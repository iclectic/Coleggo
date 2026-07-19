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
