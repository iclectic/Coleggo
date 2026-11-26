import { randomUUID } from 'crypto';
import type { NextFunction, Request, Response } from 'express';
import { recordRequestSample } from '../lib/requestMetrics';

export function requestLogging(req: Request, res: Response, next: NextFunction) {
  const requestId = (req.headers['x-request-id'] as string | undefined) || randomUUID();
  const started = Date.now();
  res.setHeader('x-request-id', requestId);

  res.on('finish', () => {
    const latencyMs = Date.now() - started;
    const userId = (req as Request & { userId?: string }).userId;
    const entry = {
      level: 'info',
      msg: 'request',
      requestId,
      method: req.method,
      path: req.path,
      status: res.statusCode,
      latencyMs,
      userIdHash: userId ? hashShort(userId) : null,
    };
    // Structured JSON logs for staging on-call without a heavy logging dependency.
    console.log(JSON.stringify(entry));
    recordRequestSample({
      at: Date.now(),
      path: req.path,
      method: req.method,
      status: res.statusCode,
      latencyMs,
    });
  });

  next();
}

function hashShort(value: string): string {
  let hash = 0;
  for (let i = 0; i < value.length; i += 1) {
    hash = ((hash << 5) - hash) + value.charCodeAt(i);
    hash |= 0;
  }
  return `u${Math.abs(hash).toString(16).slice(0, 8)}`;
}
