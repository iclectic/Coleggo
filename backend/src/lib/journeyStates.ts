import { JourneyState } from '@prisma/client';

const allowedTransitions: Record<JourneyState, JourneyState[]> = {
  scheduled: ['awaitingConfirmation', 'cancelled', 'archived'],
  awaitingConfirmation: ['confirmed', 'cancelled', 'missed', 'archived'],
  confirmed: ['completed', 'cancelled', 'archived'],
  completed: ['archived'],
  cancelled: ['archived'],
  missed: ['archived'],
  archived: [],
};

export function canTransition(from: JourneyState, to: JourneyState): boolean {
  if (from === to) return true;
  return allowedTransitions[from].includes(to);
}

export function assertTransition(from: JourneyState, to: JourneyState): void {
  if (!canTransition(from, to)) {
    throw new Error(`Invalid journey transition from ${from} to ${to}`);
  }
}
