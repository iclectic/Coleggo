import { Router } from 'express';
import { z } from 'zod';
import { recordEvent } from '../lib/audit';
import { withIdempotency } from '../lib/idempotency';
import { assessMessageBody } from '../lib/messageSafety';
import { prisma } from '../lib/prisma';
import { isInQuietHours } from '../lib/quietHours';
import { checkRateLimit } from '../lib/rateLimit';
import { paramId, requireAuth, type AuthRequest } from '../middleware/auth';

const router = Router();

const MESSAGE_RATE_LIMIT = 20;
const MESSAGE_RATE_WINDOW_MS = 60_000;

async function requireCircleMember(userId: string, circleId: string) {
  const profile = await prisma.profile.findUnique({ where: { userId } });
  if (!profile) {
    return { ok: false as const, error: 'Profile not found', status: 404 as const };
  }
  const membership = await prisma.circleMembership.findUnique({
    where: { circleId_profileId: { circleId, profileId: profile.id } },
  });
  if (!membership || membership.paused) {
    return {
      ok: false as const,
      error: 'Only active circle members can access messages',
      status: 403 as const,
    };
  }
  return { ok: true as const, profile, membership };
}

async function getOrCreateThread(circleId: string) {
  return prisma.messageThread.upsert({
    where: { circleId },
    create: { circleId },
    update: {},
  });
}

router.get('/circles/:id/messages', requireAuth, async (req: AuthRequest, res) => {
  const circleId = paramId(req, 'id');
  if (!circleId) { res.status(400).json({ error: 'Invalid id' }); return; }
  const access = await requireCircleMember(req.userId!, circleId);
  if (!access.ok) {
    res.status(access.status).json({ error: access.error });
    return;
  }
  const thread = await getOrCreateThread(circleId);
  const messages = await prisma.message.findMany({
    where: { threadId: thread.id, deliveryState: { not: 'removed' } },
    orderBy: { createdAt: 'asc' },
    take: 200,
    include: { sender: true },
  });
  res.json({
    threadId: thread.id,
    messages: messages.map((message) => ({
      id: message.id,
      threadId: message.threadId,
      senderProfileId: message.senderProfileId,
      senderFirstName: message.sender.firstName,
      senderInitials: message.sender.initials,
      body: message.body,
      deliveryState: message.deliveryState,
      sentAt: message.createdAt,
    })),
  });
});

router.post('/circles/:id/messages', requireAuth, withIdempotency, async (req: AuthRequest, res) => {
  const circleId = paramId(req, 'id');
  if (!circleId) { res.status(400).json({ error: 'Invalid id' }); return; }
  const schema = z.object({ body: z.string().min(1).max(2000) });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid message' });
    return;
  }
  const access = await requireCircleMember(req.userId!, circleId);
  if (!access.ok) {
    res.status(access.status).json({ error: access.error });
    return;
  }
  const { profile } = access;

  const sharedLimit = checkRateLimit(`message:${profile.id}`, MESSAGE_RATE_LIMIT, MESSAGE_RATE_WINDOW_MS);
  if (!sharedLimit.allowed) {
    res.status(429).json({ error: 'Message rate limit exceeded. Please wait a minute.' });
    return;
  }
  const recentCount = await prisma.message.count({
    where: {
      senderProfileId: profile.id,
      createdAt: { gte: new Date(Date.now() - MESSAGE_RATE_WINDOW_MS) },
    },
  });
  if (recentCount >= MESSAGE_RATE_LIMIT) {
    res.status(429).json({ error: 'Message rate limit exceeded. Please wait a minute.' });
    return;
  }

  const deliveryState = assessMessageBody(parsed.data.body);
  const thread = await getOrCreateThread(circleId);
  const message = await prisma.message.create({
    data: {
      threadId: thread.id,
      senderProfileId: profile.id,
      body: parsed.data.body.trim(),
      deliveryState,
    },
    include: { sender: true },
  });

  // Create in-app notifications for other members, respecting quiet hours.
  const members = await prisma.circleMembership.findMany({
    where: { circleId, paused: false, profileId: { not: profile.id } },
    include: { profile: { include: { user: true } } },
  });
  const now = new Date();
  for (const member of members) {
    if (isInQuietHours(now, member.profile.quietHoursStart, member.profile.quietHoursEnd)) {
      continue;
    }
    await prisma.notification.create({
      data: {
        userId: member.profile.userId,
        type: 'secureMessage',
        title: 'New circle message',
        body: `${message.sender.firstName} sent a message in your Commute Circle.`,
      },
    });
  }

  res.status(201).json({
    message: {
      id: message.id,
      threadId: message.threadId,
      senderProfileId: message.senderProfileId,
      senderFirstName: message.sender.firstName,
      senderInitials: message.sender.initials,
      body: message.body,
      deliveryState: message.deliveryState,
      sentAt: message.createdAt,
    },
  });
});

router.post('/messages/:id/report', requireAuth, withIdempotency, async (req: AuthRequest, res) => {
  const messageId = paramId(req, 'id');
  if (!messageId) { res.status(400).json({ error: 'Invalid id' }); return; }
  const schema = z.object({ reason: z.string().min(3).max(500) });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid report' });
    return;
  }
  const message = await prisma.message.findUnique({
    where: { id: messageId },
    include: { thread: true },
  });
  if (!message) {
    res.status(404).json({ error: 'Message not found' });
    return;
  }
  const access = await requireCircleMember(req.userId!, message.thread.circleId);
  if (!access.ok) {
    res.status(access.status).json({ error: access.error });
    return;
  }
  const report = await prisma.messageModerationReport.upsert({
    where: {
      messageId_reporterId: {
        messageId,
        reporterId: req.userId!,
      },
    },
    create: {
      messageId,
      reporterId: req.userId!,
      reason: parsed.data.reason,
    },
    update: {
      reason: parsed.data.reason,
      status: 'submitted',
    },
  });
  await prisma.message.update({
    where: { id: messageId },
    data: { deliveryState: 'flagged' },
  });
  await recordEvent({
    type: 'moderation.reported',
    actorUserId: req.userId,
    subjectType: 'message',
    subjectId: messageId,
    payload: { reportId: report.id, reason: parsed.data.reason },
  });
  res.status(201).json({ report });
});

export default router;
