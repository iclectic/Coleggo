import { MembershipRole, RequestStatus } from '@prisma/client';
import { Router } from 'express';
import { z } from 'zod';
import { recordEvent } from '../lib/audit';
import { withIdempotency } from '../lib/idempotency';
import { prisma } from '../lib/prisma';
import { checkRateLimit } from '../lib/rateLimit';
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
    where: {
      worksiteId: profile.worksiteId,
      state: { in: ['active', 'full', 'forming', 'paused'] },
    },
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
      backupDriverId: circle.backupDriverId,
      memberCount: circle._count.memberships,
      pendingRequestCount: circle._count.requests,
    })),
  });
});

async function requireOrganiser(userId: string | undefined, circleId: string) {
  const profile = await prisma.profile.findUnique({ where: { userId } });
  if (!profile) {
    return { ok: false as const, error: 'Profile not found', status: 404 as const };
  }
  const membership = await prisma.circleMembership.findUnique({
    where: { circleId_profileId: { circleId, profileId: profile.id } },
  });
  const isOrganiser = membership
    && (membership.role === MembershipRole.organiser || membership.role === MembershipRole.driver);
  if (!isOrganiser) {
    return {
      ok: false as const,
      error: 'Only organisers can manage this circle',
      status: 403 as const,
    };
  }
  return { ok: true as const, profile, membership };
}

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
    backupDriverId: circle.backupDriverId,
    members: circle.memberships.map((m) => ({
      id: m.profile.id,
      firstName: m.profile.firstName,
      initials: m.profile.initials,
      role: m.role,
      paused: m.paused,
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

router.post('/:id/pause', requireAuth, withIdempotency, async (req: AuthRequest, res) => {
  const id = paramId(req, 'id');
  if (!id) { res.status(400).json({ error: 'Invalid id' }); return; }
  const access = await requireOrganiser(req.userId, id);
  if (!access.ok) {
    res.status(access.status).json({ error: access.error });
    return;
  }
  const circle = await prisma.commuteCircle.update({
    where: { id },
    data: { state: 'paused' },
  });
  res.json({ circle });
});

router.post('/:id/resume', requireAuth, withIdempotency, async (req: AuthRequest, res) => {
  const id = paramId(req, 'id');
  if (!id) { res.status(400).json({ error: 'Invalid id' }); return; }
  const access = await requireOrganiser(req.userId, id);
  if (!access.ok) {
    res.status(access.status).json({ error: access.error });
    return;
  }
  const memberCount = await prisma.circleMembership.count({ where: { circleId: id } });
  const circle = await prisma.commuteCircle.findUnique({ where: { id } });
  if (!circle) {
    res.status(404).json({ error: 'Circle not found' });
    return;
  }
  const nextState = memberCount >= circle.seats ? 'full' : 'active';
  const updated = await prisma.commuteCircle.update({
    where: { id },
    data: { state: nextState },
  });
  res.json({ circle: updated });
});

router.patch('/:id', requireAuth, withIdempotency, async (req: AuthRequest, res) => {
  const id = paramId(req, 'id');
  if (!id) { res.status(400).json({ error: 'Invalid id' }); return; }
  const schema = z.object({
    seats: z.number().int().min(1).max(8).optional(),
    departureWindow: z.string().min(3).optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid update' });
    return;
  }
  const access = await requireOrganiser(req.userId, id);
  if (!access.ok) {
    res.status(access.status).json({ error: access.error });
    return;
  }
  const circle = await prisma.commuteCircle.update({
    where: { id },
    data: {
      seats: parsed.data.seats,
      departureWindow: parsed.data.departureWindow,
    },
  });
  res.json({ circle });
});

router.post('/:id/backup-driver', requireAuth, withIdempotency, async (req: AuthRequest, res) => {
  const id = paramId(req, 'id');
  if (!id) { res.status(400).json({ error: 'Invalid id' }); return; }
  const schema = z.object({ profileId: z.string().min(1) });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid backup driver' });
    return;
  }
  const access = await requireOrganiser(req.userId, id);
  if (!access.ok) {
    res.status(access.status).json({ error: access.error });
    return;
  }
  const membership = await prisma.circleMembership.findUnique({
    where: {
      circleId_profileId: { circleId: id, profileId: parsed.data.profileId },
    },
  });
  if (!membership) {
    res.status(400).json({ error: 'Backup driver must already be a circle member' });
    return;
  }
  await prisma.circleMembership.update({
    where: { id: membership.id },
    data: { role: MembershipRole.backupDriver },
  });
  const circle = await prisma.commuteCircle.update({
    where: { id },
    data: { backupDriverId: parsed.data.profileId },
  });
  res.json({ circle });
});

router.get('/:id/attendance-summary', requireAuth, async (req: AuthRequest, res) => {
  const id = paramId(req, 'id');
  if (!id) { res.status(400).json({ error: 'Invalid id' }); return; }
  const profile = await prisma.profile.findUnique({ where: { userId: req.userId } });
  if (!profile) {
    res.status(404).json({ error: 'Profile not found' });
    return;
  }
  const membership = await prisma.circleMembership.findUnique({
    where: { circleId_profileId: { circleId: id, profileId: profile.id } },
  });
  if (!membership) {
    res.status(403).json({ error: 'Only circle members can view attendance summaries' });
    return;
  }
  const journeys = await prisma.journeyOccurrence.findMany({
    where: { circleId: id },
    include: { attendances: true },
    orderBy: { scheduledFor: 'desc' },
    take: 14,
  });
  res.json({
    circleId: id,
    summaries: journeys.map((journey) => ({
      journeyId: journey.id,
      scheduledFor: journey.scheduledFor,
      state: journey.state,
      confirmed: journey.attendances.filter((a) => a.status === 'travelling').length,
      notTravelling: journey.attendances.filter((a) => a.status === 'notTravelling').length,
      undecided: journey.attendances.filter((a) => a.status === 'unsure').length,
      totalMembers: journey.attendances.length,
    })),
  });
});

router.post('/:id/pause-participation', requireAuth, withIdempotency, async (req: AuthRequest, res) => {
  const id = paramId(req, 'id');
  if (!id) { res.status(400).json({ error: 'Invalid id' }); return; }
  const schema = z.object({ paused: z.boolean() });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid request' });
    return;
  }
  const profile = await prisma.profile.findUnique({ where: { userId: req.userId } });
  if (!profile) {
    res.status(404).json({ error: 'Profile not found' });
    return;
  }
  const membership = await prisma.circleMembership.update({
    where: { circleId_profileId: { circleId: id, profileId: profile.id } },
    data: { paused: parsed.data.paused },
  });
  await recordEvent({
    type: 'membership.paused',
    actorUserId: req.userId,
    subjectType: 'circle',
    subjectId: id,
    payload: { paused: parsed.data.paused, membershipId: membership.id },
  });
  res.json({ membership });
});

router.post('/:id/leave', requireAuth, withIdempotency, async (req: AuthRequest, res) => {
  const id = paramId(req, 'id');
  if (!id) { res.status(400).json({ error: 'Invalid id' }); return; }
  const profile = await prisma.profile.findUnique({ where: { userId: req.userId } });
  if (!profile) {
    res.status(404).json({ error: 'Profile not found' });
    return;
  }
  await prisma.circleMembership.delete({
    where: { circleId_profileId: { circleId: id, profileId: profile.id } },
  });
  const remaining = await prisma.circleMembership.count({ where: { circleId: id } });
  if (remaining === 0) {
    await prisma.commuteCircle.update({
      where: { id },
      data: { state: 'archived' },
    });
  }
  await recordEvent({
    type: 'membership.left',
    actorUserId: req.userId,
    subjectType: 'circle',
    subjectId: id,
    payload: { remainingMembers: remaining },
  });
  res.json({ left: true, remainingMembers: remaining });
});

router.post('/:id/join', requireAuth, withIdempotency, async (req: AuthRequest, res) => {
  const id = paramId(req, 'id');
  if (!id) { res.status(400).json({ error: 'Invalid id' }); return; }
  const rate = checkRateLimit(`join:${req.userId}`, 10, 60_000);
  if (!rate.allowed) {
    res.status(429).json({ error: 'Too many join attempts. Please wait a minute.' });
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
  await recordEvent({
    type: 'membership.join_requested',
    actorUserId: req.userId,
    subjectType: 'circle',
    subjectId: circle.id,
    payload: { requestId: request.id },
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
  await recordEvent({
    type: 'membership.accepted',
    actorUserId: req.userId,
    subjectType: 'circle',
    subjectId: circle.id,
    payload: { requestId: request.id, requesterId: request.requesterId },
  });
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
