import { JourneyState, MembershipRole, PrismaClient } from '@prisma/client';

function startOfUtcDay(date: Date): Date {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
}

function addDays(date: Date, days: number): Date {
  const next = new Date(date);
  next.setUTCDate(next.getUTCDate() + days);
  return next;
}

function parseDepartureStartMinutes(window: string): number {
  const match = /^(\d{1,2}):(\d{2})/.exec(window);
  if (!match) return 7 * 60;
  return Number(match[1]) * 60 + Number(match[2]);
}

/** Generate upcoming journey occurrences for active circles over the next N days. */
export async function generateUpcomingJourneys(
  prisma: PrismaClient,
  options: { daysAhead?: number; now?: Date } = {},
): Promise<{ created: number; skipped: number }> {
  const daysAhead = options.daysAhead ?? 14;
  const now = options.now ?? new Date();
  const today = startOfUtcDay(now);

  const circles = await prisma.commuteCircle.findMany({
    where: { state: { in: ['active', 'full'] } },
    include: {
      memberships: true,
    },
  });

  let created = 0;
  let skipped = 0;

  for (const circle of circles) {
    const organiser = circle.memberships.find((member) => member.role === MembershipRole.organiser)
      ?? circle.memberships.find((member) => member.role === MembershipRole.driver)
      ?? circle.memberships[0];
    const departureMinutes = parseDepartureStartMinutes(circle.departureWindow);

    for (let offset = 0; offset < daysAhead; offset += 1) {
      const day = addDays(today, offset);
      // JS getUTCDay: 0 Sunday ... 6 Saturday. Product days use 1=Mon ... 7=Sun.
      const productDay = day.getUTCDay() === 0 ? 7 : day.getUTCDay();
      if (!circle.days.includes(productDay)) continue;

      const scheduledFor = new Date(day);
      scheduledFor.setUTCMinutes(departureMinutes);

      if (scheduledFor.getTime() < now.getTime() - 60 * 60 * 1000) {
        skipped += 1;
        continue;
      }

      try {
        await prisma.journeyOccurrence.create({
          data: {
            circleId: circle.id,
            scheduledFor,
            state: JourneyState.scheduled,
            driverId: organiser?.profileId,
            attendances: {
              create: circle.memberships.map((member) => ({
                profileId: member.profileId,
                status: 'unsure',
              })),
            },
          },
        });
        created += 1;
      } catch {
        skipped += 1;
      }
    }
  }

  return { created, skipped };
}
