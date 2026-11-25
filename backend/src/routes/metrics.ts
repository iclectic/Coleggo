import { AttendanceStatus, JourneyState } from '@prisma/client';
import { Router } from 'express';
import { prisma } from '../lib/prisma';
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
    where: { worksiteId: profile.worksiteId, state: { in: ['active', 'full'] } },
    include: {
      memberships: true,
      journeys: {
        include: {
          attendances: true,
          cancellations: true,
        },
      },
    },
  });

  const activeCircles = circles.length;
  let seatCapacity = 0;
  let occupiedSeats = 0;
  let expectedAttendances = 0;
  let confirmedAttendances = 0;
  let cancelledJourneys = 0;
  let cancelledWithBackup = 0;

  for (const circle of circles) {
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

  res.json({
    worksiteId: profile.worksiteId,
    metrics: {
      activeCircles,
      circleFillRate: seatCapacity === 0 ? 0 : occupiedSeats / seatCapacity,
      confirmationRate: expectedAttendances === 0 ? 0 : confirmedAttendances / expectedAttendances,
      lateCancellationRate: null,
      backupCoverage: cancelledJourneys === 0 ? null : cancelledWithBackup / cancelledJourneys,
      verificationIntegrity: totalProfiles === 0 ? 0 : verifiedProfiles / totalProfiles,
    },
  });
});

export default router;
