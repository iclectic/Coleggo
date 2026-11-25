import { Router } from 'express';
import { prisma } from '../lib/prisma';
import { requireAuth, type AuthRequest } from '../middleware/auth';

const router = Router();

router.get('/', async (_req, res) => {
  const workplaces = await prisma.workplace.findMany({
    include: { worksites: true },
    orderBy: { name: 'asc' },
  });
  res.json({
    workplaces: workplaces.map((workplace) => ({
      id: workplace.id,
      name: workplace.name,
      slug: workplace.slug,
      domain: workplace.domain,
      worksites: workplace.worksites.map((worksite) => ({
        id: worksite.id,
        name: worksite.name,
      })),
    })),
  });
});

router.get('/me', requireAuth, async (req: AuthRequest, res) => {
  const profile = await prisma.profile.findUnique({
    where: { userId: req.userId },
    include: { worksite: { include: { workplace: { include: { worksites: true } } } } },
  });
  if (!profile) {
    res.status(404).json({ error: 'Profile not found' });
    return;
  }
  const workplace = profile.worksite.workplace;
  res.json({
    workplace: {
      id: workplace.id,
      name: workplace.name,
      slug: workplace.slug,
      domain: workplace.domain,
      worksites: workplace.worksites.map((worksite) => ({
        id: worksite.id,
        name: worksite.name,
      })),
    },
    worksiteId: profile.worksiteId,
    workplaceVerified: profile.workplaceVerified,
  });
});

export default router;
