import { Router } from 'express';
import { prisma } from '../lib/prisma';
import { buildReliabilityProfile } from '../lib/reliability';
import { paramId, requireAuth, type AuthRequest } from '../middleware/auth';

const router = Router();

router.get('/me', requireAuth, async (req: AuthRequest, res) => {
  const profile = await prisma.profile.findUnique({ where: { userId: req.userId } });
  if (!profile) {
    res.status(404).json({ error: 'Profile not found' });
    return;
  }
  const reliability = await buildReliabilityProfile(prisma, profile.id);
  res.json({ reliability });
});

router.get('/:profileId', requireAuth, async (req: AuthRequest, res) => {
  const profileId = paramId(req, 'profileId');
  if (!profileId) {
    res.status(400).json({ error: 'Invalid profile id' });
    return;
  }

  const current = await prisma.profile.findUnique({ where: { userId: req.userId } });
  if (!current) {
    res.status(404).json({ error: 'Profile not found' });
    return;
  }

  const reliability = await buildReliabilityProfile(prisma, profileId);
  if (!reliability) {
    res.status(404).json({ error: 'Reliability profile not found' });
    return;
  }

  // Private-by-default: other users only see non-warning journey summaries.
  if (current.id !== profileId) {
    res.json({
      reliability: {
        profileId: reliability.profileId,
        workplaceVerified: reliability.workplaceVerified,
        signals: reliability.signals.filter((signal) => !signal.warning),
      },
    });
    return;
  }

  res.json({ reliability });
});

export default router;
