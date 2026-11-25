import { MembershipRole, RequestStatus } from '@prisma/client';
import { Router } from 'express';
import { z } from 'zod';
import { withIdempotency } from '../lib/idempotency';
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
    where: { worksiteId: profile.worksiteId, state: { in: ['active', 'full', 'forming'] } },
    include: {
      _count: { select: { memberships: true, requests: true } },
    },
  });
  res.json({
    circles: circles.map((circle) => ({
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
      journeys: {
        where: { state: { in: ['scheduled', 'awaitingConfirmation', 'confirmed'] } },
        orderBy: { scheduledFor: 'asc' },
        take: 1,
      },
    },
  });
  if (!circle) {
    res.status(404).json({ error: 'Circle not found' });
    return;
  }
  const profile = await prisma.profile.findUnique({ where: { userId: req.userId } });
  const isMember = circle.memberships.some((m) => m.profileId === profile?.id);
  const existingRequest = circle.requests.find(
    (r) => r.requesterId === req.userId && r.status === RequestStatus.pending,
  );
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
    members: circle.memberships.map((m) => ({
      id: m.profile.id,
      firstName: m.profile.firstName,
      initials: m.profile.initials,
      role: m.role,
    })),
    requests: isMember
      ? circle.requests
          .filter((r) => r.status === RequestStatus.pending)
          .map((r) => ({
            id: r.id,
            requesterId: r.requesterId,
            firstName: r.requester.profile?.firstName,
            initials: r.requester.profile?.initials,
            message: r.message,
            status: r.status,
            circleId: r.circleId,
            createdAt: r.createdAt,
          }))
      : [],
    nextJourney: circle.journeys[0]
      ? { id: circle.journeys[0].id, scheduledFor: circle.journeys[0].scheduledFor, state: circle.journeys[0].state }
      : null,
  });
});

router.post('/:id/join', requireAuth, withIdempotency, async (req: AuthRequest, res) => {
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
  const isMember = circle.memberships.some((m) => m.profileId === profile.id);
  if (isMember) {
    res.status(409).json({ error: 'Already a member' });
    return;
  }
  const existingPending = circle.requests.some(
    (r) => r.requesterId === req.userId && r.status === RequestStatus.pending,
  );
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

router.post('/:id/accept', requireAuth, withIdempotency, async (req: AuthRequest, res) => {
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
  const isOrganiser = circle.memberships.some(
    (m) =>
      m.profileId === profile?.id
      && (m.role === MembershipRole.organiser || m.role === MembershipRole.driver),
  );
  if (!isOrganiser && circle.memberships.length > 0) {
    res.status(403).json({ error: 'Only organisers can accept requests' });
    return;
  }
  const request = await prisma.commuteRequest.update({
    where: { id: parsed.data.requestId },
    data: { status: RequestStatus.accepted },
    include: { requester: { include: { profile: true } } },
  });
  if (request.requester.profile) {
    await prisma.circleMembership.upsert({
      where: {
        circleId_profileId: {
          circleId: circle.id,
          profileId: request.requester.profile.id,
        },
      },
      create: {
        circleId: circle.id,
        profileId: request.requester.profile.id,
        role: MembershipRole.passenger,
      },
      update: {},
    });
  }
  res.json({ request });
});

router.post('/:id/decline', requireAuth, withIdempotency, async (req: AuthRequest, res) => {
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
    data: { status: RequestStatus.declined },
  });
  res.json({ request });
});

export default router;
