import { Router } from 'express';
import { prisma } from '../lib/prisma';
import { rankMatches, type MatchProfile } from '../lib/matching';
import { requireAuth, type AuthRequest } from '../middleware/auth';

const router = Router();

function toMatchProfile(profile: {
  id: string;
  firstName: string;
  initials: string;
  role: MatchProfile['role'];
  worksiteId: string;
  homeArea: string;
  corridor: string;
  postcodeDistrict: string | null;
  approxLatitude: number | null;
  approxLongitude: number | null;
  days: number[];
  arrivalMinutes: number;
  departureMinutes: number;
  availableSeats: number;
  vehicleSummary: string | null;
}): MatchProfile {
  return {
    id: profile.id,
    firstName: profile.firstName,
    initials: profile.initials,
    role: profile.role,
    worksiteId: profile.worksiteId,
    homeArea: profile.homeArea,
    corridor: profile.corridor,
    postcodeDistrict: profile.postcodeDistrict,
    approxLatitude: profile.approxLatitude,
    approxLongitude: profile.approxLongitude,
    days: profile.days,
    arrivalMinutes: profile.arrivalMinutes,
    departureMinutes: profile.departureMinutes,
    availableSeats: profile.availableSeats,
    vehicleSummary: profile.vehicleSummary,
  };
}

router.get('/', requireAuth, async (req: AuthRequest, res) => {
  const profile = await prisma.profile.findUnique({ where: { userId: req.userId } });
  if (!profile) {
    res.status(404).json({ error: 'Profile not found' });
    return;
  }

  const candidates = await prisma.profile.findMany({
    where: {
      worksiteId: profile.worksiteId,
      id: { not: profile.id },
    },
  });

  const matches = rankMatches(
    toMatchProfile(profile),
    candidates.map(toMatchProfile),
  );

  res.json({ matches });
});

export default router;
