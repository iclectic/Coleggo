import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { getRuntimeConfig } from '../lib/runtimeConfig';

export interface AuthRequest extends Request {
  userId?: string;
}

const { jwtSecret: JWT_SECRET } = getRuntimeConfig();

export function requireAuth(req: AuthRequest, res: Response, next: NextFunction): void {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }
  const token = header.slice(7);
  try {
    const payload = jwt.verify(token, JWT_SECRET) as { userId: string };
    req.userId = payload.userId;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid token' });
  }
}

export function signToken(userId: string): string {
  return jwt.sign({ userId }, JWT_SECRET, { expiresIn: '7d' });
}

export function paramId(req: AuthRequest, name: string): string | undefined {
  const value = req.params[name];
  return Array.isArray(value) ? value[0] : value;
}
