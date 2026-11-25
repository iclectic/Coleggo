import { createHash, randomBytes } from 'crypto';
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { prisma } from '../lib/prisma';
import { getRuntimeConfig } from '../lib/runtimeConfig';

export interface AuthRequest extends Request {
  userId?: string;
}

const { jwtSecret: JWT_SECRET } = getRuntimeConfig();

/** Short-lived access tokens; refresh tokens rotate separately. */
export const ACCESS_TOKEN_TTL = '15m';
export const REFRESH_TOKEN_TTL_DAYS = 30;

export function requireAuth(req: AuthRequest, res: Response, next: NextFunction): void {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }
  const token = header.slice(7);
  try {
    const payload = jwt.verify(token, JWT_SECRET) as { userId: string; typ?: string };
    if (payload.typ && payload.typ !== 'access') {
      res.status(401).json({ error: 'Invalid token' });
      return;
    }
    req.userId = payload.userId;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid token' });
  }
}

export function signAccessToken(userId: string): string {
  return jwt.sign({ userId, typ: 'access' }, JWT_SECRET, { expiresIn: ACCESS_TOKEN_TTL });
}

/** @deprecated Prefer signAccessToken; kept for older unit tests. */
export function signToken(userId: string): string {
  return signAccessToken(userId);
}

export function hashRefreshToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}

export async function issueRefreshToken(userId: string): Promise<string> {
  const raw = randomBytes(48).toString('hex');
  const tokenHash = hashRefreshToken(raw);
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + REFRESH_TOKEN_TTL_DAYS);
  await prisma.refreshToken.create({
    data: { userId, tokenHash, expiresAt },
  });
  return raw;
}

export async function rotateRefreshToken(rawToken: string): Promise<{ userId: string; refreshToken: string } | null> {
  const tokenHash = hashRefreshToken(rawToken);
  const existing = await prisma.refreshToken.findUnique({ where: { tokenHash } });
  if (!existing || existing.revokedAt || existing.expiresAt.getTime() < Date.now()) {
    return null;
  }
  await prisma.refreshToken.update({
    where: { id: existing.id },
    data: { revokedAt: new Date() },
  });
  const refreshToken = await issueRefreshToken(existing.userId);
  return { userId: existing.userId, refreshToken };
}

export function paramId(req: AuthRequest, name: string): string | undefined {
  const value = req.params[name];
  return Array.isArray(value) ? value[0] : value;
}
