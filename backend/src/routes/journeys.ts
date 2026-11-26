import { AttendanceStatus, JourneyState, MembershipRole } from '@prisma/client';
import { Router } from 'express';
import { z } from 'zod';
import { recordEvent } from '../lib/audit';
import { withIdempotency } from '../lib/idempotency';
import { assertTransition } from '../lib/journeyStates';
import { prisma } from '../lib/prisma';
import { checkRateLimit } from '../lib/rateLimit';
import { paramId, requireAuth, type AuthRequest } from '../middleware/auth';

const router = Router();

/**
 * Conflict rule for attendance: server upsert wins. Clients may queue offline
 * confirmations and replay with Idempotency-Key; the latest accepted server
 * write updates Attendance.updatedAt.
 */

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
    where: {
      circleId: membership.circleId,
      state: { in: [JourneyState.scheduled, JourneyState.awaitingConfirmation, JourneyState.confirmed] },
    },
    orderBy: { scheduledFor: 'asc' },
    include: {
      circle: { include: { memberships: true } },
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

router.post('/:id/confirm', requireAuth, withIdempotency, async (req: AuthRequest, res) => {
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
  const journey = await prisma.journeyOccurrence.findUnique({ where: { id } });
  if (!journey) {
    res.status(404).json({ error: 'Journey not found' });
    return;
  }
  if (
    journey.state !== JourneyState.scheduled
    && journey.state !== JourneyState.awaitingConfirmation
    && journey.state !== JourneyState.confirmed
  ) {
    res.status(400).json({ error: 'Journey cannot be confirmed in its current state' });
    return;
  }

  const rate = checkRateLimit(`confirm:${req.userId}`, 30, 60_000);
  if (!rate.allowed) {
    res.status(429).json({ error: 'Too many confirmation attempts. Please wait a minute.' });
    return;
  }

  const attendance = await prisma.attendance.upsert({
    where: { journeyId_profileId: { journeyId: id, profileId: profile.id } },
    create: { journeyId: id, profileId: profile.id, status: parsed.data.status },
    update: { status: parsed.data.status },
    include: { journey: { include: { circle: true } } },
  });

  if (journey.state === JourneyState.scheduled || journey.state === JourneyState.awaitingConfirmation) {
    try {
      assertTransition(journey.state, JourneyState.confirmed);
      await prisma.journeyOccurrence.update({
        where: { id },
        data: { state: JourneyState.confirmed },
      });
    } catch {
      // Keep existing state if transition is not allowed.
    }
  }

  await recordEvent({
    type: 'attendance.confirmed',
    actorUserId: req.userId,
    subjectType: 'journey',
    subjectId: id,
    payload: { status: parsed.data.status, attendanceId: attendance.id },
  });

  res.json({ attendance });
});

router.post('/:id/cancel', requireAuth, withIdempotency, async (req: AuthRequest, res) => {
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
  const existing = await prisma.journeyOccurrence.findUnique({ where: { id } });
  if (!existing) {
    res.status(404).json({ error: 'Journey not found' });
    return;
  }
  try {
    assertTransition(existing.state, JourneyState.cancelled);
  } catch {
    res.status(400).json({ error: `Cannot cancel journey from state ${existing.state}` });
    return;
  }

  const journey = await prisma.journeyOccurrence.update({
    where: { id },
    data: { state: JourneyState.cancelled },
    include: {
      attendances: true,
      circle: { include: { memberships: { include: { profile: true } } } },
    },
  });
  const affected = journey.attendances.filter((a) => a.status === AttendanceStatus.travelling).length;
  await prisma.cancellationRecord.create({
    data: {
      journeyId: journey.id,
      cancelledById: profile.id,
      reason: parsed.data.reason,
      affectedPassengers: affected,
    },
  });
  await recordEvent({
    type: 'journey.cancelled',
    actorUserId: req.userId,
    subjectType: 'journey',
    subjectId: journey.id,
    payload: { reason: parsed.data.reason, affectedPassengers: affected },
  });

  const backupCandidates = journey.circle.memberships
    .filter((member) => member.profileId !== profile.id)
    .filter((member) => member.role === MembershipRole.driver
      || member.role === MembershipRole.backupDriver
      || member.role === MembershipRole.organiser
      || member.profile.role === 'driver'
      || member.profile.role === 'both')
    .map((member) => ({
      id: member.profile.id,
      firstName: member.profile.firstName,
      initials: member.profile.initials,
      role: member.role,
      availableSeats: member.profile.availableSeats,
    }));

  res.json({ journey, affectedPassengers: affected, backupCandidates });
});

router.post('/:id/backup', requireAuth, withIdempotency, async (req: AuthRequest, res) => {
  const id = paramId(req, 'id');
  if (!id) { res.status(400).json({ error: 'Invalid id' }); return; }
  const schema = z.object({ driverProfileId: z.string() });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid driver' });
    return;
  }
  const cancelled = await prisma.journeyOccurrence.findUnique({
    where: { id },
    include: { circle: { include: { memberships: true } } },
  });
  if (!cancelled || cancelled.state !== JourneyState.cancelled) {
    res.status(400).json({ error: 'Journey is not cancelled' });
    return;
  }
  const replacement = await prisma.journeyOccurrence.create({
    data: {
      circleId: cancelled.circleId,
      // Offset by 1 minute to satisfy unique(circleId, scheduledFor) while keeping same day.
      scheduledFor: new Date(cancelled.scheduledFor.getTime() + 60 * 1000),
      state: JourneyState.scheduled,
      driverId: parsed.data.driverProfileId,
      attendances: {
        create: cancelled.circle.memberships.map((member) => ({
          profileId: member.profileId,
          status: AttendanceStatus.unsure,
        })),
      },
    },
    include: { circle: true },
  });
  await recordEvent({
    type: 'journey.backup_selected',
    actorUserId: req.userId,
    subjectType: 'journey',
    subjectId: cancelled.id,
    payload: {
      replacementJourneyId: replacement.id,
      driverProfileId: parsed.data.driverProfileId,
    },
  });
  res.json({ replacement });
});

function toJourneyDto(journey: any, currentProfileId: string) {
  const confirmed = journey.attendances.filter(
    (a: any) => a.status === AttendanceStatus.travelling,
  ).length;
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
