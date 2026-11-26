import { Router } from 'express';
import bcrypt from 'bcrypt';
import { z } from 'zod';
import { prisma } from '../lib/prisma';
import {
  emailMatchesWorkplace,
  isVerificationCurrent,
  verificationExpiresAt,
} from '../lib/workplaceAccess';
import {
  issueRefreshToken,
  requireAuth,
  rotateRefreshToken,
  signAccessToken,
  type AuthRequest,
} from '../middleware/auth';

const router = Router();

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  firstName: z.string().min(1),
  initials: z.string().min(1).max(3),
  worksiteId: z.string().min(1),
  homeArea: z.string().min(1),
  corridor: z.string().min(1),
  days: z.array(z.number().int().min(1).max(7)),
  arrivalMinutes: z.number().int(),
  departureMinutes: z.number().int(),
  role: z.enum(['driver', 'passenger', 'both']),
  availableSeats: z.number().int().default(0),
  vehicleSummary: z.string().optional(),
  invitationCode: z.string().min(4).optional(),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

const migrateSchema = z.object({
  profile: z.object({
    firstName: z.string().min(1),
    initials: z.string().min(1).max(3),
    homeArea: z.string().min(1),
    corridor: z.string().min(1),
    days: z.array(z.number().int().min(1).max(7)),
    arrivalMinutes: z.number().int(),
    departureMinutes: z.number().int(),
    role: z.enum(['driver', 'passenger', 'both']),
    availableSeats: z.number().int().default(0),
    vehicleSummary: z.string().optional(),
  }).optional(),
  commute: z.object({
    days: z.array(z.number().int().min(1).max(7)),
    arrivalMinutes: z.number().int(),
    departureMinutes: z.number().int(),
  }).optional(),
  circles: z.array(z.object({
    name: z.string().min(1),
    shiftLabel: z.string().default('standardOffice'),
    days: z.array(z.number().int().min(1).max(7)),
    departureWindow: z.string().default('07:00-09:00'),
    seats: z.number().int().default(0),
  })).default([]),
});

async function authPayload(userId: string) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    include: { profile: { include: { worksite: { include: { workplace: true } } } } },
  });
  if (!user) return null;
  const accessToken = signAccessToken(user.id);
  const refreshToken = await issueRefreshToken(user.id);
  return {
    token: accessToken,
    accessToken,
    refreshToken,
    expiresIn: 15 * 60,
    user: toUserDto(user),
  };
}

router.post('/register', async (req, res) => {
  const parsed = registerSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid registration data', issues: parsed.error.flatten() });
    return;
  }
  const data = parsed.data;
  const existing = await prisma.user.findUnique({ where: { email: data.email } });
  if (existing) {
    res.status(409).json({ error: 'Email already registered' });
    return;
  }
  const worksite = await prisma.worksite.findUnique({
    where: { id: data.worksiteId },
    include: { workplace: true },
  });
  if (!worksite) {
    res.status(400).json({ error: 'Invalid worksite' });
    return;
  }
  if (data.invitationCode) {
    const inviteWorkplace = await prisma.workplace.findUnique({
      where: { invitationCode: data.invitationCode },
    });
    if (!inviteWorkplace || inviteWorkplace.id !== worksite.workplaceId) {
      res.status(400).json({ error: 'Invitation code does not match the selected workplace' });
      return;
    }
  }
  if (!emailMatchesWorkplace(data.email, worksite.workplace) && !data.invitationCode) {
    // Allow registration with invitation even when personal email is used;
    // workplace verification still required before discovery trust.
  }
  const passwordHash = await bcrypt.hash(data.password, 10);
  const user = await prisma.user.create({
    data: {
      email: data.email,
      passwordHash,
      profile: {
        create: {
          worksiteId: data.worksiteId,
          firstName: data.firstName,
          initials: data.initials,
          role: data.role,
          homeArea: data.homeArea,
          corridor: data.corridor,
          days: data.days,
          arrivalMinutes: data.arrivalMinutes,
          departureMinutes: data.departureMinutes,
          availableSeats: data.availableSeats,
          vehicleSummary: data.vehicleSummary,
        },
      },
    },
  });
  const payload = await authPayload(user.id);
  res.status(201).json(payload);
});

router.post('/redeem-invite', async (req, res) => {
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

router.post('/login', async (req, res) => {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid login data' });
    return;
  }
  const user = await prisma.user.findUnique({
    where: { email: parsed.data.email },
  });
  if (!user || !(await bcrypt.compare(parsed.data.password, user.passwordHash))) {
    res.status(401).json({ error: 'Invalid email or password' });
    return;
  }
  const payload = await authPayload(user.id);
  res.json(payload);
});

router.post('/refresh', async (req, res) => {
  const schema = z.object({ refreshToken: z.string().min(1) });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid refresh token' });
    return;
  }
  const rotated = await rotateRefreshToken(parsed.data.refreshToken);
  if (!rotated) {
    res.status(401).json({ error: 'Invalid refresh token' });
    return;
  }
  const accessToken = signAccessToken(rotated.userId);
  res.json({
    token: accessToken,
    accessToken,
    refreshToken: rotated.refreshToken,
    expiresIn: 15 * 60,
  });
});

router.get('/me', requireAuth, async (req: AuthRequest, res) => {
  const user = await prisma.user.findUnique({
    where: { id: req.userId },
    include: { profile: { include: { worksite: { include: { workplace: true } } } } },
  });
  if (!user) {
    res.status(404).json({ error: 'User not found' });
    return;
  }
  res.json({ user: toUserDto(user) });
});

router.post('/verify-workplace', requireAuth, async (req: AuthRequest, res) => {
  const schema = z.object({ email: z.string().email() });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid email' });
    return;
  }
  const user = await prisma.user.findUnique({
    where: { id: req.userId },
    include: { profile: { include: { worksite: { include: { workplace: true } } } } },
  });
  if (!user?.profile) {
    res.status(404).json({ error: 'Profile not found' });
    return;
  }
  const workplace = user.profile.worksite.workplace;
  const matches = emailMatchesWorkplace(parsed.data.email, workplace);
  let expiresAt: Date | null = null;
  if (matches) {
    const verifiedAt = new Date();
    await prisma.profile.update({
      where: { id: user.profile.id },
      data: { workplaceVerified: true, verifiedAt },
    });
    expiresAt = verificationExpiresAt(verifiedAt, workplace.verificationValidDays);
  }
  res.json({
    verified: matches,
    expiresAt,
    message: matches
      ? 'Workplace domain matched. This confirms access to a workplace email, not driving ability, insurance, criminal history or personal character. Verification renews periodically.'
      : 'Email domain does not match the selected workplace allowlist.',
  });
});

router.patch('/preferences', requireAuth, async (req: AuthRequest, res) => {
  const schema = z.object({
    quietHoursStart: z.number().int().min(0).max(1439).nullable().optional(),
    quietHoursEnd: z.number().int().min(0).max(1439).nullable().optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid preferences' });
    return;
  }
  const profile = await prisma.profile.findUnique({ where: { userId: req.userId } });
  if (!profile) {
    res.status(404).json({ error: 'Profile not found' });
    return;
  }
  const updated = await prisma.profile.update({
    where: { id: profile.id },
    data: {
      quietHoursStart: parsed.data.quietHoursStart ?? profile.quietHoursStart,
      quietHoursEnd: parsed.data.quietHoursEnd ?? profile.quietHoursEnd,
    },
  });
  res.json({
    quietHoursStart: updated.quietHoursStart,
    quietHoursEnd: updated.quietHoursEnd,
  });
});

router.delete('/account', requireAuth, async (req: AuthRequest, res) => {
  const user = await prisma.user.findUnique({
    where: { id: req.userId },
    include: { profile: { include: { memberships: { select: { circleId: true } } } } },
  });
  if (!user) {
    res.status(404).json({ error: 'User not found' });
    return;
  }
  const circleIds = user.profile?.memberships.map((membership) => membership.circleId) ?? [];
  await prisma.$transaction(async (transaction) => {
    await transaction.user.delete({ where: { id: user.id } });
    for (const circleId of circleIds) {
      const memberCount = await transaction.circleMembership.count({
        where: { circleId },
      });
      if (memberCount === 0) {
        await transaction.commuteCircle.delete({ where: { id: circleId } });
      }
    }
  });
  res.status(204).send();
});

router.post('/migrate', requireAuth, async (req: AuthRequest, res) => {
  const parsed = migrateSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid migration data', issues: parsed.error.flatten() });
    return;
  }
  const data = parsed.data;
  const user = await prisma.user.findUnique({
    where: { id: req.userId },
    include: { profile: { include: { worksite: true } } },
  });
  if (!user?.profile) {
    res.status(404).json({ error: 'Profile not found' });
    return;
  }

  const profile = user.profile;
  const role = data.profile?.role ?? profile.role;
  const days = data.profile?.days ?? data.commute?.days ?? profile.days;
  const arrivalMinutes = data.profile?.arrivalMinutes ?? data.commute?.arrivalMinutes ?? profile.arrivalMinutes;
  const departureMinutes = data.profile?.departureMinutes ?? data.commute?.departureMinutes ?? profile.departureMinutes;

  await prisma.profile.update({
    where: { id: profile.id },
    data: {
      firstName: data.profile?.firstName ?? profile.firstName,
      initials: data.profile?.initials ?? profile.initials,
      homeArea: data.profile?.homeArea ?? profile.homeArea,
      corridor: data.profile?.corridor ?? profile.corridor,
      days,
      arrivalMinutes,
      departureMinutes,
      role,
      availableSeats: data.profile?.availableSeats ?? profile.availableSeats,
      vehicleSummary: data.profile?.vehicleSummary ?? profile.vehicleSummary,
    },
  });

  let circlesCreated = 0;
  let membershipsCreated = 0;

  for (const localCircle of data.circles) {
    const existing = await prisma.commuteCircle.findFirst({
      where: { worksiteId: profile.worksiteId, name: localCircle.name },
    });
    if (existing) continue;
    const circle = await prisma.commuteCircle.create({
      data: {
        worksiteId: profile.worksiteId,
        name: localCircle.name,
        shiftLabel: localCircle.shiftLabel,
        days: localCircle.days,
        departureWindow: localCircle.departureWindow,
        seats: localCircle.seats,
        state: 'active',
      },
    });
    circlesCreated += 1;
    const alreadyMember = await prisma.circleMembership.findUnique({
      where: { circleId_profileId: { circleId: circle.id, profileId: profile.id } },
    });
    if (!alreadyMember) {
      await prisma.circleMembership.create({
        data: {
          circleId: circle.id,
          profileId: profile.id,
          role: 'organiser',
        },
      });
      membershipsCreated += 1;
    }
  }

  const updated = await prisma.user.findUnique({
    where: { id: req.userId },
    include: { profile: { include: { worksite: { include: { workplace: true } } } } },
  });
  res.json({
    migrated: true,
    circlesCreated,
    membershipsCreated,
    user: toUserDto(updated!),
  });
});

function toUserDto(user: any) {
  const workplace = user.profile?.worksite?.workplace;
  const verificationCurrent = user.profile && workplace
    ? isVerificationCurrent(user.profile, workplace)
    : false;
  const expiresAt = user.profile?.verifiedAt && workplace
    ? verificationExpiresAt(user.profile.verifiedAt, workplace.verificationValidDays)
    : null;
  return {
    id: user.id,
    email: user.email,
    profile: user.profile
      ? {
          id: user.profile.id,
          firstName: user.profile.firstName,
          initials: user.profile.initials,
          role: user.profile.role,
          homeArea: user.profile.homeArea,
          corridor: user.profile.corridor,
          days: user.profile.days,
          arrivalMinutes: user.profile.arrivalMinutes,
          departureMinutes: user.profile.departureMinutes,
          availableSeats: user.profile.availableSeats,
          vehicleSummary: user.profile.vehicleSummary,
          workplaceVerified: user.profile.workplaceVerified ?? false,
          verificationCurrent,
          verifiedAt: user.profile.verifiedAt,
          verificationExpiresAt: expiresAt,
          quietHoursStart: user.profile.quietHoursStart,
          quietHoursEnd: user.profile.quietHoursEnd,
          worksite: {
            id: user.profile.worksite.id,
            name: user.profile.worksite.name,
            workplace: {
              id: user.profile.worksite.workplace.id,
              name: user.profile.worksite.workplace.name,
              domain: user.profile.worksite.workplace.domain,
              verificationValidDays: user.profile.worksite.workplace.verificationValidDays,
            },
          },
        }
      : null,
  };
}

export default router;
