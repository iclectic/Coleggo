import { Router } from 'express';
import { z } from 'zod';
import { recordEvent } from '../lib/audit';
import { withIdempotency } from '../lib/idempotency';
import { prisma } from '../lib/prisma';
import { paramId, requireAuth, type AuthRequest } from '../middleware/auth';

const router = Router();

router.patch('/reports/:id', requireAuth, withIdempotency, async (req: AuthRequest, res) => {
  const id = paramId(req, 'id');
  if (!id) {
    res.status(400).json({ error: 'Invalid id' });
    return;
  }
  const schema = z.object({
    status: z.enum(['reviewed', 'dismissed', 'escalated']),
    note: z.string().max(500).optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid moderation update' });
    return;
  }

  const existing = await prisma.messageModerationReport.findUnique({ where: { id } });
  if (!existing) {
    res.status(404).json({ error: 'Report not found' });
    return;
  }

  const resolvedAt = parsed.data.status === 'escalated' ? null : new Date();
  const report = await prisma.messageModerationReport.update({
    where: { id },
    data: {
      status: parsed.data.status,
      resolvedAt,
    },
  });

  await recordEvent({
    type: parsed.data.status === 'escalated' ? 'moderation.escalated' : 'moderation.reviewed',
    actorUserId: req.userId,
    subjectType: 'message_moderation_report',
    subjectId: report.id,
    payload: {
      status: report.status,
      messageId: report.messageId,
      note: parsed.data.note ?? null,
    },
  });

  res.json({ report });
});

export default router;
