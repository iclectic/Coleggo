import { Router } from 'express';
import { prisma } from '../lib/prisma';
import { applyRetention } from '../lib/jobs/applyRetention';
import { advanceConfirmationWindows } from '../lib/jobs/confirmationWindows';
import { generateUpcomingJourneys } from '../lib/jobs/generateJourneys';
import { requireAuth, type AuthRequest } from '../middleware/auth';

const router = Router();

function manualJobsAllowed(res: import('express').Response): boolean {
  if (process.env.NODE_ENV === 'production' && process.env.ALLOW_MANUAL_JOBS !== 'true') {
    res.status(403).json({ error: 'Manual jobs are disabled in production' });
    return false;
  }
  return true;
}

/**
 * Manual job triggers for staging/dev and integration tests.
 * In production these should run from a scheduler, not public clients.
 */
router.post('/generate-journeys', requireAuth, async (_req: AuthRequest, res) => {
  if (!manualJobsAllowed(res)) return;
  const result = await generateUpcomingJourneys(prisma);
  res.json(result);
});

router.post('/advance-confirmation-windows', requireAuth, async (_req: AuthRequest, res) => {
  if (!manualJobsAllowed(res)) return;
  const result = await advanceConfirmationWindows(prisma);
  res.json(result);
});

router.post('/apply-retention', requireAuth, async (_req: AuthRequest, res) => {
  if (!manualJobsAllowed(res)) return;
  const result = await applyRetention(prisma);
  res.json(result);
});

export default router;
