import type { Prisma } from '@prisma/client';
import { prisma } from './prisma';

export type DomainEventType =
  | 'membership.join_requested'
  | 'membership.accepted'
  | 'membership.left'
  | 'membership.paused'
  | 'attendance.confirmed'
  | 'journey.cancelled'
  | 'journey.backup_selected'
  | 'moderation.reported'
  | 'moderation.reviewed'
  | 'moderation.escalated'
  | 'account.exported'
  | 'account.delete_blocked'
  | 'account.deleted';

export async function recordEvent(input: {
  type: DomainEventType | string;
  actorUserId?: string | null;
  subjectType: string;
  subjectId: string;
  payload?: Prisma.InputJsonObject;
}) {
  return prisma.domainEvent.create({
    data: {
      type: input.type,
      actorUserId: input.actorUserId ?? null,
      subjectType: input.subjectType,
      subjectId: input.subjectId,
      payload: input.payload ?? {},
    },
  });
}
