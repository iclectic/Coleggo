import type { PrismaClient } from '@prisma/client';

const DAY_MS = 24 * 60 * 60 * 1000;

export async function applyRetention(
  prisma: PrismaClient,
  options?: { now?: Date },
) {
  const now = options?.now ?? new Date();
  const reportCutoff = new Date(now.getTime() - 365 * DAY_MS);
  const idempotencyCutoff = new Date(now.getTime() - 7 * DAY_MS);
  const eventCutoff = new Date(now.getTime() - 30 * DAY_MS);

  const activeUserHolds = await prisma.legalHold.findMany({
    where: { active: true, scope: 'user' },
    select: { subjectId: true },
  });
  const heldUserIds = new Set(
    activeUserHolds.map((hold) => hold.subjectId).filter(Boolean) as string[],
  );
  const globalHold = await prisma.legalHold.findFirst({
    where: { active: true, scope: 'global' },
  });

  let reportsPurged = 0;
  let idempotencyPurged = 0;
  let eventsAnonymised = 0;

  if (!globalHold) {
    const resolvedReports = await prisma.messageModerationReport.findMany({
      where: {
        status: { in: ['reviewed', 'dismissed'] },
        resolvedAt: { lte: reportCutoff },
      },
      select: { id: true, reporterId: true },
    });
    const deletable = resolvedReports.filter((report) => !heldUserIds.has(report.reporterId));
    if (deletable.length > 0) {
      const result = await prisma.messageModerationReport.deleteMany({
        where: { id: { in: deletable.map((report) => report.id) } },
      });
      reportsPurged = result.count;
    }

    const idempotency = await prisma.idempotencyKey.deleteMany({
      where: { createdAt: { lte: idempotencyCutoff } },
    });
    idempotencyPurged = idempotency.count;

    // Keep audit rows but drop actor linkage after the security-log window.
    const anonymised = await prisma.domainEvent.updateMany({
      where: {
        createdAt: { lte: eventCutoff },
        actorUserId: { not: null },
      },
      data: { actorUserId: null },
    });
    eventsAnonymised = anonymised.count;
  }

  return {
    reportsPurged,
    idempotencyPurged,
    eventsAnonymised,
    skippedDueToGlobalHold: !!globalHold,
  };
}
