import { AttendanceStatus, JourneyState } from '@prisma/client';
import { Router } from 'express';
import { buildCapacityHints } from '../lib/capacityHints';
import { prisma } from '../lib/prisma';
import { getSloSnapshot } from '../lib/requestMetrics';
import { requireAuth, type AuthRequest } from '../middleware/auth';

const router = Router();

/** Efficiency SLIs for the authenticated user's worksite (employer-safe aggregates). */
router.get('/efficiency', requireAuth, async (req: AuthRequest, res) => {
  const profile = await prisma.profile.findUnique({ where: { userId: req.userId } });
  if (!profile) {
    res.status(404).json({ error: 'Profile not found' });
    return;
  }

  const circles = await prisma.commuteCircle.findMany({
    where: { worksiteId: profile.worksiteId, state: { in: ['active', 'full', 'paused'] } },
    include: {
      memberships: { include: { profile: true } },
      journeys: {
        include: {
          attendances: true,
          cancellations: true,
        },
      },
    },
  });

  const activeCircles = circles.filter((circle) => circle.state === 'active' || circle.state === 'full').length;
  let seatCapacity = 0;
  let occupiedSeats = 0;
  let expectedAttendances = 0;
  let confirmedAttendances = 0;
  let cancelledJourneys = 0;
  let cancelledWithBackup = 0;

  for (const circle of circles) {
    if (circle.state !== 'active' && circle.state !== 'full') continue;
    seatCapacity += circle.seats;
    occupiedSeats += Math.min(circle.memberships.length, circle.seats);

    for (const journey of circle.journeys) {
      expectedAttendances += journey.attendances.length;
      confirmedAttendances += journey.attendances.filter(
        (attendance) => attendance.status === AttendanceStatus.travelling,
      ).length;

      if (journey.state === JourneyState.cancelled) {
        cancelledJourneys += 1;
        const hasBackup = circle.journeys.some(
          (other) =>
            other.id !== journey.id
            && other.scheduledFor.getTime() === journey.scheduledFor.getTime()
            && other.state !== JourneyState.cancelled
            && other.driverId
            && other.driverId !== journey.driverId,
        );
        if (hasBackup) cancelledWithBackup += 1;
      }
    }
  }

  const verifiedProfiles = await prisma.profile.count({
    where: { worksiteId: profile.worksiteId, workplaceVerified: true },
  });
  const totalProfiles = await prisma.profile.count({
    where: { worksiteId: profile.worksiteId },
  });

  const corridorGroups = await prisma.profile.groupBy({
    by: ['corridor'],
    where: { worksiteId: profile.worksiteId },
    _count: { corridor: true },
  });

  const worksiteProfiles = await prisma.profile.findMany({
    where: { worksiteId: profile.worksiteId },
    select: { corridor: true, days: true },
  });
  const capacityHints = buildCapacityHints({
    profiles: worksiteProfiles,
    circles: circles.map((circle) => {
      const corridors = circle.memberships.map((member) => member.profile.corridor);
      const corridorHint = corridors.sort((a, b) =>
        corridors.filter((value) => value === b).length
        - corridors.filter((value) => value === a).length)[0] ?? null;
      return {
        corridorHint,
        days: circle.days,
        seats: circle.seats,
      };
    }),
  });

  res.json({
    worksiteId: profile.worksiteId,
    metrics: {
      activeCircles,
      circleFillRate: seatCapacity === 0 ? 0 : occupiedSeats / seatCapacity,
      confirmationRate: expectedAttendances === 0 ? 0 : confirmedAttendances / expectedAttendances,
      lateCancellationRate: null,
      backupCoverage: cancelledJourneys === 0 ? null : cancelledWithBackup / cancelledJourneys,
      verificationIntegrity: totalProfiles === 0 ? 0 : verifiedProfiles / totalProfiles,
      corridorDensity: corridorGroups
        .map((group) => ({
          corridor: group.corridor,
          commuterCount: group._count.corridor,
        }))
        .sort((a, b) => b.commuterCount - a.commuterCount),
      capacityHints,
    },
  });
});

/** Rolling in-process API latency / error-budget snapshot for staging on-call. */
router.get('/slo', requireAuth, async (_req: AuthRequest, res) => {
  res.json({ slo: getSloSnapshot() });
});

/** Recent domain audit events for the authenticated actor (on-call diagnosis). */
router.get('/audit-events', requireAuth, async (req: AuthRequest, res) => {
  const events = await prisma.domainEvent.findMany({
    where: { actorUserId: req.userId },
    orderBy: { createdAt: 'desc' },
    take: 100,
  });
  res.json({ events });
});

export default router;
