import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../lib/prisma';
import { paramId, requireAuth, type AuthRequest } from '../middleware/auth';

const router = Router();

router.get('/next', requireAuth, async (req: AuthRequest, res) => {
  const profile = await prisma.profile.findUnique({ where: { userId: req.userId } });
  if (!profile) {
    res.status(404).json({ error: 'Profile not found' });
    return;
  }
  const membership = await prisma.circleMembership.findFirst({
    where: { profileId: profile.id },
    include: { circle: true },
  });
  if (!membership) {
    res.json({ journey: null });
    return;
  }
  const journey = await prisma.journeyOccurrence.findFirst({
    where: { circleId: membership.circleId, state: { in: ['scheduled', 'awaitingConfirmation', 'confirmed'] } },
    orderBy: { scheduledFor: 'asc' },
    include: {
      circle: true,
      attendances: { include: { profile: true } },
      cancellations: true,
    },
  });
  if (!journey) {
    res.json({ journey: null });
    return;
  }
  res.json({ journey: toJourneyDto(journey, profile.id) });
});

router.post('/:id/confirm', requireAuth, async (req: AuthRequest, res) => {
  const id = paramId(req, 'id');
  if (!id) { res.status(400).json({ error: 'Invalid id' }); return; }
  const schema = z.object({ status: z.enum(['travelling', 'notTravelling', 'unsure']) });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid status' });
    return;
  }
  const profile = await prisma.profile.findUnique({ where: { userId: req.userId } });
  if (!profile) {
    res.status(404).json({ error: 'Profile not found' });
    return;
  }
  const attendance = await prisma.attendance.upsert({
    where: { journeyId_profileId: { journeyId: id, profileId: profile.id } },
    create: { journeyId: id, profileId: profile.id, status: parsed.data.status },
    update: { status: parsed.data.status },
    include: { journey: { include: { circle: true } } },
  });
  res.json({ attendance });
});

router.post('/:id/cancel', requireAuth, async (req: AuthRequest, res) => {
  const id = paramId(req, 'id');
  if (!id) { res.status(400).json({ error: 'Invalid id' }); return; }
  const schema = z.object({ reason: z.string().min(1) });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid reason' });
    return;
  }
  const profile = await prisma.profile.findUnique({ where: { userId: req.userId } });
  if (!profile) {
    res.status(404).json({ error: 'Profile not found' });
    return;
  }
  const journey = await prisma.journeyOccurrence.update({
    where: { id },
    data: { state: 'cancelled' },
    include: { attendances: true, circle: { include: { memberships: { include: { profile: true } } } } },
  });
  const affected = journey.attendances.filter((a: any) => a.status === 'travelling').length;
  await prisma.cancellationRecord.create({
    data: {
      journeyId: journey.id,
      cancelledById: profile.id,
      reason: parsed.data.reason,
      affectedPassengers: affected,
    },
  });
  res.json({ journey, affectedPassengers: affected });
});

router.post('/:id/backup', requireAuth, async (req: AuthRequest, res) => {
  const id = paramId(req, 'id');
  if (!id) { res.status(400).json({ error: 'Invalid id' }); return; }
  const schema = z.object({ driverProfileId: z.string() });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid driver' });
    return;
  }
  const cancelled = await prisma.journeyOccurrence.findUnique({ where: { id } });
  if (!cancelled || cancelled.state !== 'cancelled') {
    res.status(400).json({ error: 'Journey is not cancelled' });
    return;
  }
  const replacement = await prisma.journeyOccurrence.create({
    data: {
      circleId: cancelled.circleId,
      scheduledFor: cancelled.scheduledFor,
      state: 'scheduled',
      driverId: parsed.data.driverProfileId,
    },
    include: { circle: true },
  });
  res.json({ replacement });
});

function toJourneyDto(journey: any, currentProfileId: string) {
  const confirmed = journey.attendances.filter((a: any) => a.status === 'travelling').length;
  const total = journey.circle.memberships?.length ?? journey.attendances.length;
  const myAttendance = journey.attendances.find((a: any) => a.profileId === currentProfileId);
  return {
    id: journey.id,
    circleId: journey.circleId,
    scheduledFor: journey.scheduledFor,
    state: journey.state,
    confirmedCount: confirmed,
    totalCount: total,
    myStatus: myAttendance?.status ?? null,
    members: journey.attendances.map((a: any) => ({
      id: a.profile.id,
      firstName: a.profile.firstName,
      initials: a.profile.initials,
      status: a.status,
    })),
    cancellations: journey.cancellations.map((c: any) => ({
      id: c.id,
      reason: c.reason,
      affectedPassengers: c.affectedPassengers,
    })),
  };
}

export default router;
