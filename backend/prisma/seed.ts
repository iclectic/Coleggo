import bcrypt from 'bcrypt';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  await prisma.$transaction([
    prisma.messageModerationReport.deleteMany(),
    prisma.message.deleteMany(),
    prisma.messageThread.deleteMany(),
    prisma.idempotencyKey.deleteMany(),
    prisma.refreshToken.deleteMany(),
    prisma.cancellationRecord.deleteMany(),
    prisma.attendance.deleteMany(),
    prisma.journeyOccurrence.deleteMany(),
    prisma.circleMembership.deleteMany(),
    prisma.commuteRequest.deleteMany(),
    prisma.commuteCircle.deleteMany(),
    prisma.notification.deleteMany(),
    prisma.profile.deleteMany(),
    prisma.user.deleteMany(),
    prisma.worksite.deleteMany(),
    prisma.workplace.deleteMany(),
  ]);

  const passwordHash = await bcrypt.hash('Password123!', 10);
  const verifiedAt = new Date();

  const workplace = await prisma.workplace.create({
    data: {
      name: 'Northstar Works',
      slug: 'northstar',
      domain: 'northstar.example',
      allowedDomains: ['northstar-contractors.example'],
      invitationCode: 'NORTH-PILOT',
      verificationValidDays: 90,
    },
  });

  const worksite = await prisma.worksite.create({
    data: { workplaceId: workplace.id, name: 'Central Exchange' },
  });

  const driverProfile = await prisma.profile.create({
    data: {
      user: {
        create: {
          email: 'asha@northstar.example',
          passwordHash,
        },
      },
      worksite: { connect: { id: worksite.id } },
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
      workplaceVerified: true,
      verifiedAt,
    },
    include: { user: true },
  });

  const passengerProfile = await prisma.profile.create({
    data: {
      user: {
        create: {
          email: 'ben@northstar.example',
          passwordHash,
        },
      },
      worksite: { connect: { id: worksite.id } },
      firstName: 'Ben',
      initials: 'BE',
      role: 'passenger',
      homeArea: 'Solihull',
      corridor: 'Solihull to city centre',
      days: [1, 3, 5],
      arrivalMinutes: 510,
      departureMinutes: 1050,
      availableSeats: 0,
      workplaceVerified: true,
      verifiedAt,
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
      backupDriverId: null,
      memberships: {
        create: [
          { profileId: driverProfile.id, role: 'organiser' },
          { profileId: passengerProfile.id, role: 'passenger' },
        ],
      },
    },
  });

  console.log(`Seeded ${workplace.name} / ${worksite.name} / ${circle.name}`);
  console.log('Invitation code: NORTH-PILOT');
  console.log('Demo logins: asha@northstar.example / ben@northstar.example password Password123!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
