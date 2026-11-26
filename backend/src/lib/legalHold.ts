import { prisma } from './prisma';

export async function hasActiveLegalHold(input: {
  userId?: string;
  workplaceId?: string;
}): Promise<boolean> {
  const orClauses: Array<{ scope: string; subjectId?: string | null }> = [
    { scope: 'global', subjectId: null },
  ];
  if (input.userId) {
    orClauses.push({ scope: 'user', subjectId: input.userId });
  }
  if (input.workplaceId) {
    orClauses.push({ scope: 'workplace', subjectId: input.workplaceId });
  }
  const hold = await prisma.legalHold.findFirst({
    where: {
      active: true,
      OR: orClauses,
    },
  });
  return !!hold;
}
