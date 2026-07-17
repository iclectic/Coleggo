import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../lib/prisma';
import { paramId, requireAuth, type AuthRequest } from '../middleware/auth';

const router = Router();

router.get('/', requireAuth, async (req: AuthRequest, res) => {
  const profile = await prisma.profile.findUnique({
    where: { userId: req.userId },
    include: { worksite: true },
  });
  if (!profile) {
    res.status(404).json({ error: 'Profile not found' });
    return;
  }
  const circles = await prisma.commuteCircle.findMany({
    where: { worksiteId: profile.worksiteId, state: 'active' },
    include: {
      _count: { select: { memberships: true, requests: true } },
    },
  });
  res.json({
    circles: circles.map((circle: any) => ({
      id: circle.id,
      name: circle.name,
      shiftLabel: circle.shiftLabel,
      days: circle.days,
      departureWindow: circle.departureWindow,
      seats: circle.seats,
      state: circle.state,
      memberCount: circle._count.memberships,
      pendingRequestCount: circle._count.requests,
    })),
  });
});

router.get('/:id', requireAuth, async (req: AuthRequest, res) => {
  const id = paramId(req, 'id');
  if (!id) { res.status(400).json({ error: 'Invalid id' }); return; }
  const circle = await prisma.commuteCircle.findUnique({
    where: { id },
    include: {
      worksite: { include: { workplace: true } },
      memberships: { include: { profile: true } },
      requests: { include: { requester: { include: { profile: true } } } },
      journeys: { orderBy: { scheduledFor: 'asc' }, take: 1 },
    },
  });
  if (!circle) {
    res.status(404).json({ error: 'Circle not found' });
    return;
  }
  const profile = await prisma.profile.findUnique({ where: { userId: req.userId } });
  const isMember = circle.memberships.some((m: any) => m.profileId === profile?.id);
  const existingRequest = circle.requests.find((r: any) => r.requesterId === req.userId && r.status === 'pending');
  res.json({
    id: circle.id,
    name: circle.name,
    shiftLabel: circle.shiftLabel,
    days: circle.days,
    departureWindow: circle.departureWindow,
    seats: circle.seats,
    state: circle.state,
    isMember,
    hasPendingRequest: !!existingRequest,
    members: circle.memberships.map((m: any) => ({
      id: m.profile.id,
      firstName: m.profile.firstName,
      initials: m.profile.initials,
      role: m.role,
    })),
    requests: isMember
      ? circle.requests
          .filter((r: any) => r.status === 'pending')
          .map((r: any) => ({
            id: r.id,
            requesterId: r.requesterId,
            firstName: r.requester.profile?.firstName,
            initials: r.requester.profile?.initials,
            message: r.message,
          }))
      : [],
    nextJourney: circle.journeys[0]
      ? { id: circle.journeys[0].id, scheduledFor: circle.journeys[0].scheduledFor, state: circle.journeys[0].state }
      : null,
  });
});

router.post('/:id/join', requireAuth, async (req: AuthRequest, res) => {
  const id = paramId(req, 'id');
  if (!id) { res.status(400).json({ error: 'Invalid id' }); return; }
  const circle = await prisma.commuteCircle.findUnique({
    where: { id },
    include: { memberships: true, requests: true },
  });
  if (!circle) {
    res.status(404).json({ error: 'Circle not found' });
    return;
  }
  const profile = await prisma.profile.findUnique({ where: { userId: req.userId } });
  if (!profile) {
    res.status(404).json({ error: 'Profile not found' });
    return;
  }
  const isMember = circle.memberships.some((m: any) => m.profileId === profile.id);
  if (isMember) {
    res.status(409).json({ error: 'Already a member' });
    return;
  }
  const existingPending = circle.requests.some((r: any) => r.requesterId === req.userId && r.status === 'pending');
  if (existingPending) {
    res.status(409).json({ error: 'Join request already pending' });
    return;
  }
  const request = await prisma.commuteRequest.create({
    data: {
      circleId: circle.id,
      requesterId: req.userId!,
      type: 'join',
      message: req.body.message ?? '',
    },
  });
  res.status(201).json({ request });
});

router.post('/:id/accept', requireAuth, async (req: AuthRequest, res) => {
  const id = paramId(req, 'id');
  if (!id) { res.status(400).json({ error: 'Invalid id' }); return; }
  const schema = z.object({ requestId: z.string() });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid request' });
    return;
  }
  const circle = await prisma.commuteCircle.findUnique({
    where: { id },
    include: { memberships: true, requests: true },
  });
  if (!circle) {
    res.status(404).json({ error: 'Circle not found' });
    return;
  }
  const profile = await prisma.profile.findUnique({ where: { userId: req.userId } });
  const isOrganiser = circle.memberships.some((m: any) => m.profileId === profile?.id && m.role === 'organiser');
  if (!isOrganiser && circle.memberships.length > 0) {
    res.status(403).json({ error: 'Only organisers can accept requests' });
    return;
  }
  const request = await prisma.commuteRequest.update({
    where: { id: parsed.data.requestId },
    data: { status: 'accepted' },
    include: { requester: { include: { profile: true } } },
  });
  if (request.requester.profile) {
    await prisma.circleMembership.create({
      data: {
        circleId: circle.id,
        profileId: request.requester.profile.id,
        role: 'passenger',
      },
    });
  }
  res.json({ request });
});

router.post('/:id/decline', requireAuth, async (req: AuthRequest, res) => {
  const id = paramId(req, 'id');
  if (!id) { res.status(400).json({ error: 'Invalid id' }); return; }
  const schema = z.object({ requestId: z.string() });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid request' });
    return;
  }
  const request = await prisma.commuteRequest.update({
    where: { id: parsed.data.requestId },
    data: { status: 'declined' },
  });
  res.json({ request });
});

export default router;
