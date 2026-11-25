import { JourneyState, PrismaClient } from '@prisma/client';
import { canTransition } from '../journeyStates';

/**
 * Move scheduled journeys into awaitingConfirmation inside the confirmation window,
 * and mark unresolved past journeys as missed.
 */
export async function advanceConfirmationWindows(
  prisma: PrismaClient,
  options: {
    now?: Date;
    /** Hours before departure when confirmation opens. */
    openHoursBefore?: number;
  } = {},
): Promise<{ opened: number; missed: number }> {
  const now = options.now ?? new Date();
  const openHoursBefore = options.openHoursBefore ?? 24;
  const openBeforeMs = openHoursBefore * 60 * 60 * 1000;

  const scheduled = await prisma.journeyOccurrence.findMany({
    where: {
      state: JourneyState.scheduled,
      scheduledFor: {
        lte: new Date(now.getTime() + openBeforeMs),
        gt: now,
      },
    },
  });

  let opened = 0;
  for (const journey of scheduled) {
    if (!canTransition(journey.state, JourneyState.awaitingConfirmation)) continue;
    await prisma.journeyOccurrence.update({
      where: { id: journey.id },
      data: { state: JourneyState.awaitingConfirmation },
    });
    opened += 1;
  }

  const unresolved = await prisma.journeyOccurrence.findMany({
    where: {
      state: { in: [JourneyState.scheduled, JourneyState.awaitingConfirmation] },
      scheduledFor: { lt: now },
    },
  });

  let missed = 0;
  for (const journey of unresolved) {
    if (!canTransition(journey.state, JourneyState.missed)) continue;
    await prisma.journeyOccurrence.update({
      where: { id: journey.id },
      data: { state: JourneyState.missed },
    });
    missed += 1;
  }

  return { opened, missed };
}
