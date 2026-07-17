import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const workplace = await prisma.workplace.create({
    data: { name: 'Northstar Works', slug: 'northstar', domain: 'northstar.example' },
  });

  const worksite = await prisma.worksite.create({
    data: { workplaceId: workplace.id, name: 'Central Exchange' },
  });

  const driverProfile = await prisma.profile.create({
    data: {
      user: {
        create: {
          email: 'asha@northstar.example',
          passwordHash: 'not-used-for-seed',
        },
      },
      worksiteId: worksite.id,
      firstName: 'Asha',
      initials: 'AS',
      role: 'driver',
      homeArea: 'Solihull',
      corridor: 'Solihull to city centre',
      days: [1, 3, 5],
      arrivalMinutes: 510,
      departureMinutes: 1050,
      availableSeats: 3,
      vehicleSummary: 'Blue estate, child seats available',
    },
    include: { user: true },
  });

  const passengerProfile = await prisma.profile.create({
    data: {
      user: {
        create: {
          email: 'ben@northstar.example',
          passwordHash: 'not-used-for-seed',
        },
      },
      worksiteId: worksite.id,
      firstName: 'Ben',
      initials: 'BE',
      role: 'passenger',
      homeArea: 'Solihull',
      corridor: 'Solihull to city centre',
      days: [1, 3, 5],
      arrivalMinutes: 510,
      departureMinutes: 1050,
      availableSeats: 0,
    },
    include: { user: true },
  });

  const circle = await prisma.commuteCircle.create({
    data: {
      worksiteId: worksite.id,
      name: 'Solihull Early Shift Circle',
      shiftLabel: 'Early',
      days: [1, 3, 5],
      departureWindow: '07:00-07:30',
      seats: 3,
      state: 'active',
      memberships: {
        create: [
          { profileId: driverProfile.id, role: 'organiser' },
          { profileId: passengerProfile.id, role: 'passenger' },
        ],
      },
      journeys: {
        create: {
          scheduledFor: new Date(Date.now() + 24 * 60 * 60 * 1000),
          state: 'awaitingConfirmation',
          driverId: driverProfile.id,
          attendances: {
            create: [
              { profileId: driverProfile.id, status: 'travelling' },
              { profileId: passengerProfile.id, status: 'travelling' },
            ],
          },
        },
      },
    },
  });

  console.log(`Seeded ${workplace.name} / ${worksite.name} / ${circle.name}`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
