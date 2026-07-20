import { Router } from 'express';
import bcrypt from 'bcrypt';
import { z } from 'zod';
import { prisma } from '../lib/prisma';
import { requireAuth, signToken, type AuthRequest } from '../middleware/auth';

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
  const worksite = await prisma.worksite.findUnique({ where: { id: data.worksiteId } });
  if (!worksite) {
    res.status(400).json({ error: 'Invalid worksite' });
    return;
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
    include: { profile: { include: { worksite: { include: { workplace: true } } } } },
  });
  const token = signToken(user.id);
  res.status(201).json({ token, user: toUserDto(user) });
});

router.post('/login', async (req, res) => {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid login data' });
    return;
  }
  const user = await prisma.user.findUnique({
    where: { email: parsed.data.email },
    include: { profile: { include: { worksite: { include: { workplace: true } } } } },
  });
  if (!user || !(await bcrypt.compare(parsed.data.password, user.passwordHash))) {
    res.status(401).json({ error: 'Invalid email or password' });
    return;
  }
  const token = signToken(user.id);
  res.json({ token, user: toUserDto(user) });
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
  const domain = parsed.data.email.split('@')[1];
  const matches = domain === user.profile.worksite.workplace.domain;
  res.json({
    verified: matches,
    message: matches
      ? 'Workplace domain matched. This confirms access to a workplace email, not driving ability, insurance, criminal history or personal character.'
      : 'Email domain does not match the selected workplace.',
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
          worksite: {
            id: user.profile.worksite.id,
            name: user.profile.worksite.name,
            workplace: {
              id: user.profile.worksite.workplace.id,
              name: user.profile.worksite.workplace.name,
              domain: user.profile.worksite.workplace.domain,
            },
          },
        }
      : null,
  };
}

export default router;
