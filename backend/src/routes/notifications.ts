import { Router } from 'express';
import { prisma } from '../lib/prisma';
import { paramId, requireAuth, type AuthRequest } from '../middleware/auth';

const router = Router();

router.get('/', requireAuth, async (req: AuthRequest, res) => {
  const notifications = await prisma.notification.findMany({
    where: { userId: req.userId },
    orderBy: { createdAt: 'desc' },
  });
  res.json({ notifications });
});

router.post('/:id/read', requireAuth, async (req: AuthRequest, res) => {
  const id = paramId(req, 'id');
  if (!id) { res.status(400).json({ error: 'Invalid id' }); return; }
  const notification = await prisma.notification.update({
    where: { id, userId: req.userId },
    data: { read: true },
  });
  res.json({ notification });
});

router.post('/read-all', requireAuth, async (req: AuthRequest, res) => {
  await prisma.notification.updateMany({
    where: { userId: req.userId, read: false },
    data: { read: true },
  });
  res.json({ success: true });
});

export default router;
