import { prisma } from './prisma';

export async function ensureDefaultWorkplace() {
  const existing = await prisma.workplace.findUnique({ where: { slug: 'northstar' } });
  if (existing) return existing;
  return prisma.workplace.create({
    data: {
      name: 'Northstar Works',
      slug: 'northstar',
      domain: 'northstar.example',
      worksites: { create: { name: 'Central Exchange' } },
    },
    include: { worksites: true },
  });
}
