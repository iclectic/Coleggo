import { AttendanceStatus, JourneyState, PrismaClient } from '@prisma/client';

export interface ReliabilitySignalDto {
  type: string;
  label: string;
  count: number;
  warning: boolean;
}

export interface ReliabilityProfileDto {
  profileId: string;
  workplaceVerified: boolean;
  signals: ReliabilitySignalDto[];
}

export async function buildReliabilityProfile(
  prisma: PrismaClient,
  profileId: string,
): Promise<ReliabilityProfileDto | null> {
  const profile = await prisma.profile.findUnique({ where: { id: profileId } });
  if (!profile) return null;

  const [completed, memberships, lateCancellations, noShows, responses, totalAttendance] = await Promise.all([
    prisma.attendance.count({
      where: {
        profileId,
        status: AttendanceStatus.travelling,
        journey: { state: JourneyState.completed },
      },
    }),
    prisma.circleMembership.count({ where: { profileId } }),
    prisma.cancellationRecord.count({
      where: {
        cancelledById: profileId,
        createdAt: {
          // Approximate late cancel: recorded within 12h of journey time handled elsewhere;
          // for Phase 1 count all cancellations by this profile as the warning signal source.
        },
      },
    }),
    prisma.attendance.count({
      where: {
        profileId,
        status: AttendanceStatus.travelling,
        journey: { state: JourneyState.missed },
      },
    }),
    prisma.attendance.count({
      where: {
        profileId,
        status: { in: [AttendanceStatus.travelling, AttendanceStatus.notTravelling] },
      },
    }),
    prisma.attendance.count({ where: { profileId } }),
  ]);

  const signals: ReliabilitySignalDto[] = [
    {
      type: 'completedCommutes',
      label: 'Completed shared journeys',
      count: completed,
      warning: false,
    },
    {
      type: 'recurringParticipation',
      label: 'Active circle memberships',
      count: memberships,
      warning: false,
    },
    {
      type: 'responseConsistency',
      label: 'Journey responses given',
      count: responses,
      warning: false,
    },
    {
      type: 'profileCompletion',
      label: 'Profile fields completed',
      count: profile.vehicleSummary || profile.role !== 'passenger' ? 1 : 0,
      warning: false,
    },
  ];

  if (lateCancellations > 0) {
    signals.push({
      type: 'lateCancellation',
      label: 'Cancellations recorded',
      count: lateCancellations,
      warning: true,
    });
  }

  if (noShows > 0) {
    signals.push({
      type: 'noShow',
      label: 'Missed journeys after confirming',
      count: noShows,
      warning: true,
    });
  }

  // Keep unused totalAttendance referenced for future response-rate math.
  void totalAttendance;

  return {
    profileId,
    workplaceVerified: profile.workplaceVerified,
    signals,
  };
}
