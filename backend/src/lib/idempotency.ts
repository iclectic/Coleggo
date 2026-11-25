import { NextFunction, Response } from 'express';
import { prisma } from './prisma';
import type { AuthRequest } from '../middleware/auth';

export async function withIdempotency(
  req: AuthRequest,
  res: Response,
  next: NextFunction,
): Promise<void> {
  const keyHeader = req.header('Idempotency-Key');
  if (!keyHeader || !req.userId) {
    next();
    return;
  }

  const existing = await prisma.idempotencyKey.findUnique({
    where: {
      userId_key_method_path: {
        userId: req.userId,
        key: keyHeader,
        method: req.method,
        path: req.originalUrl,
      },
    },
  });

  if (existing) {
    res.status(existing.statusCode).json(existing.responseBody);
    return;
  }

  const originalJson = res.json.bind(res);
  res.json = ((body: unknown) => {
    const statusCode = res.statusCode || 200;
    void prisma.idempotencyKey
      .create({
        data: {
          userId: req.userId!,
          key: keyHeader,
          method: req.method,
          path: req.originalUrl,
          statusCode,
          responseBody: body as object,
        },
      })
      .catch(() => undefined);
    return originalJson(body);
  }) as typeof res.json;

  next();
}
