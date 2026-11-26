import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../lib/prisma';
import {
  isVerificationCurrent,
  verificationExpiresAt,
} from '../lib/workplaceAccess';
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
      allowedDomains: [workplace.domain, ...workplace.allowedDomains],
      hasInvitationCode: Boolean(workplace.invitationCode),
      verificationValidDays: workplace.verificationValidDays,
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
  const verificationCurrent = isVerificationCurrent(profile, workplace);
  res.json({
    workplace: {
      id: workplace.id,
      name: workplace.name,
      slug: workplace.slug,
      domain: workplace.domain,
      allowedDomains: [workplace.domain, ...workplace.allowedDomains],
      verificationValidDays: workplace.verificationValidDays,
      worksites: workplace.worksites.map((worksite) => ({
        id: worksite.id,
        name: worksite.name,
      })),
    },
    worksiteId: profile.worksiteId,
    workplaceVerified: profile.workplaceVerified,
    verificationCurrent,
    verifiedAt: profile.verifiedAt,
    verificationExpiresAt: profile.verifiedAt
      ? verificationExpiresAt(profile.verifiedAt, workplace.verificationValidDays)
      : null,
  });
});

/** Resolve an employer invitation without creating an account yet. */
router.post('/invite/resolve', async (req, res) => {
  const schema = z.object({ invitationCode: z.string().min(4) });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid invitation code' });
    return;
  }
  const workplace = await prisma.workplace.findUnique({
    where: { invitationCode: parsed.data.invitationCode },
    include: { worksites: true },
  });
  if (!workplace) {
    res.status(404).json({ error: 'Invitation code not found' });
    return;
  }
  res.json({
    workplace: {
      id: workplace.id,
      name: workplace.name,
      slug: workplace.slug,
      domain: workplace.domain,
      allowedDomains: [workplace.domain, ...workplace.allowedDomains],
      worksites: workplace.worksites.map((worksite) => ({
        id: worksite.id,
        name: worksite.name,
      })),
    },
  });
});

export default router;
