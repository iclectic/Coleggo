import bcrypt from 'bcrypt';
import request from 'supertest';
import { PrismaClient } from '@prisma/client';
import { createApp } from './app';

const prisma = new PrismaClient();
const app = createApp();

describe('Phase 1 production seam', () => {
  let worksiteId = '';
  let organiserToken = '';
  let passengerToken = '';
  let circleId = '';
  let journeyId = '';
  let backupDriverProfileId = '';

  beforeAll(async () => {
    await prisma.$transaction([
      prisma.messageModerationReport.deleteMany(),
      prisma.message.deleteMany(),
      prisma.messageThread.deleteMany(),
      prisma.domainEvent.deleteMany(),
      prisma.legalHold.deleteMany(),
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

    const workplace = await prisma.workplace.create({
      data: {
        name: 'Green Corridor Co',
        slug: 'green-corridor',
        domain: 'greencorridor.example',
        worksites: { create: { name: 'Riverside Campus' } },
      },
      include: { worksites: true },
    });
    worksiteId = workplace.worksites[0].id;
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it('lists workplaces without auth', async () => {
    const response = await request(app).get('/workplaces');
    expect(response.status).toBe(200);
    expect(response.body.workplaces[0].name).toBe('Green Corridor Co');
  });

  it('registers organiser and passenger, then verifies workplace', async () => {
    const organiser = await request(app).post('/auth/register').send({
      email: 'organiser@greencorridor.example',
      password: 'Password123!',
      firstName: 'Olivia',
      initials: 'OL',
      worksiteId,
      homeArea: 'Sparkbrook',
      corridor: 'Sparkbrook to riverside',
      days: [1, 2, 3, 4, 5],
      arrivalMinutes: 510,
      departureMinutes: 1050,
      role: 'driver',
      availableSeats: 3,
      vehicleSummary: 'Grey hatchback',
    });
    expect(organiser.status).toBe(201);
    expect(organiser.body.accessToken).toBeTruthy();
    expect(organiser.body.refreshToken).toBeTruthy();
    organiserToken = organiser.body.accessToken;

    const passenger = await request(app).post('/auth/register').send({
      email: 'passenger@greencorridor.example',
      password: 'Password123!',
      firstName: 'Priya',
      initials: 'PR',
      worksiteId,
      homeArea: 'Sparkbrook',
      corridor: 'Sparkbrook to riverside',
      days: [1, 3, 5],
      arrivalMinutes: 520,
      departureMinutes: 1040,
      role: 'passenger',
      availableSeats: 0,
    });
    expect(passenger.status).toBe(201);
    passengerToken = passenger.body.accessToken;

    const verified = await request(app)
      .post('/auth/verify-workplace')
      .set('Authorization', `Bearer ${organiserToken}`)
      .send({ email: 'organiser@greencorridor.example' });
    expect(verified.status).toBe(200);
    expect(verified.body.verified).toBe(true);

    const refresh = await request(app)
      .post('/auth/refresh')
      .send({ refreshToken: organiser.body.refreshToken });
    expect(refresh.status).toBe(200);
    expect(refresh.body.accessToken).toBeTruthy();
    organiserToken = refresh.body.accessToken;
  });

  it('returns server-side explainable matches', async () => {
    const response = await request(app)
      .get('/matches')
      .set('Authorization', `Bearer ${passengerToken}`);
    expect(response.status).toBe(200);
    expect(response.body.matches.length).toBeGreaterThan(0);
    expect(response.body.matches[0].breakdown.worksite).toBe(25);
    expect(response.body.matches[0].isEligible).toBe(true);
  });

  it('creates a circle via migrate then joins, accepts, generates journeys', async () => {
    const migrated = await request(app)
      .post('/auth/migrate')
      .set('Authorization', `Bearer ${organiserToken}`)
      .send({
        circles: [{
          name: 'Sparkbrook Morning Circle',
          shiftLabel: 'Early',
          days: [1, 3, 5],
          departureWindow: '07:10-07:25',
          seats: 3,
        }],
      });
    expect(migrated.status).toBe(200);
    expect(migrated.body.circlesCreated).toBe(1);

    const circles = await request(app)
      .get('/circles')
      .set('Authorization', `Bearer ${passengerToken}`);
    expect(circles.status).toBe(200);
    circleId = circles.body.circles[0].id;

    const joinKey = 'join-once-1';
    const join1 = await request(app)
      .post(`/circles/${circleId}/join`)
      .set('Authorization', `Bearer ${passengerToken}`)
      .set('Idempotency-Key', joinKey)
      .send({ message: 'Same corridor, happy to cost-share fuel later if needed.' });
    expect(join1.status).toBe(201);
    const requestId = join1.body.request.id;

    const join2 = await request(app)
      .post(`/circles/${circleId}/join`)
      .set('Authorization', `Bearer ${passengerToken}`)
      .set('Idempotency-Key', joinKey)
      .send({ message: 'Same corridor, happy to cost-share fuel later if needed.' });
    expect(join2.status).toBe(201);
    expect(join2.body.request.id).toBe(requestId);

    const accept = await request(app)
      .post(`/circles/${circleId}/accept`)
      .set('Authorization', `Bearer ${organiserToken}`)
      .set('Idempotency-Key', 'accept-once-1')
      .send({ requestId });
    expect(accept.status).toBe(200);
    expect(accept.body.request.status).toBe('accepted');

    const jobs = await request(app)
      .post('/jobs/generate-journeys')
      .set('Authorization', `Bearer ${organiserToken}`);
    expect(jobs.status).toBe(200);
    expect(jobs.body.created).toBeGreaterThan(0);

    await request(app)
      .post('/jobs/advance-confirmation-windows')
      .set('Authorization', `Bearer ${organiserToken}`);

    const next = await request(app)
      .get('/journeys/next')
      .set('Authorization', `Bearer ${passengerToken}`);
    expect(next.status).toBe(200);
    expect(next.body.journey).toBeTruthy();
    journeyId = next.body.journey.id;
  });

  it('confirms attendance, cancels, selects backup, and reports reliability + metrics', async () => {
    const confirm = await request(app)
      .post(`/journeys/${journeyId}/confirm`)
      .set('Authorization', `Bearer ${passengerToken}`)
      .set('Idempotency-Key', 'confirm-once-1')
      .send({ status: 'travelling' });
    expect(confirm.status).toBe(200);
    expect(confirm.body.attendance.status).toBe('travelling');

    const confirmAgain = await request(app)
      .post(`/journeys/${journeyId}/confirm`)
      .set('Authorization', `Bearer ${passengerToken}`)
      .set('Idempotency-Key', 'confirm-once-1')
      .send({ status: 'travelling' });
    expect(confirmAgain.status).toBe(200);

    // Add a second driver profile in the circle for backup.
    const passwordHash = await bcrypt.hash('Password123!', 10);
    const backup = await prisma.profile.create({
      data: {
        user: {
          create: {
            email: 'backup@greencorridor.example',
            passwordHash,
          },
        },
        worksite: { connect: { id: worksiteId } },
        firstName: 'Blake',
        initials: 'BL',
        role: 'driver',
        homeArea: 'Sparkbrook',
        corridor: 'Sparkbrook to riverside',
        days: [1, 3, 5],
        arrivalMinutes: 510,
        departureMinutes: 1050,
        availableSeats: 2,
        workplaceVerified: true,
      },
    });
    backupDriverProfileId = backup.id;
    await prisma.circleMembership.create({
      data: { circleId, profileId: backup.id, role: 'backupDriver' },
    });

    const cancel = await request(app)
      .post(`/journeys/${journeyId}/cancel`)
      .set('Authorization', `Bearer ${organiserToken}`)
      .set('Idempotency-Key', 'cancel-once-1')
      .send({ reason: 'Unexpected early meeting' });
    expect(cancel.status).toBe(200);
    expect(cancel.body.journey.state).toBe('cancelled');
    expect(cancel.body.backupCandidates.length).toBeGreaterThan(0);

    const backupSelect = await request(app)
      .post(`/journeys/${journeyId}/backup`)
      .set('Authorization', `Bearer ${organiserToken}`)
      .set('Idempotency-Key', 'backup-once-1')
      .send({ driverProfileId: backupDriverProfileId });
    expect(backupSelect.status).toBe(200);
    expect(backupSelect.body.replacement.driverId).toBe(backupDriverProfileId);

    const reliability = await request(app)
      .get('/reliability/me')
      .set('Authorization', `Bearer ${passengerToken}`);
    expect(reliability.status).toBe(200);
    expect(reliability.body.reliability.profileId).toBeTruthy();
    expect(Array.isArray(reliability.body.reliability.signals)).toBe(true);

    const metrics = await request(app)
      .get('/metrics/efficiency')
      .set('Authorization', `Bearer ${organiserToken}`);
    expect(metrics.status).toBe(200);
    expect(metrics.body.metrics.activeCircles).toBeGreaterThan(0);
    expect(metrics.body.metrics.circleFillRate).toBeGreaterThan(0);
  });
});
