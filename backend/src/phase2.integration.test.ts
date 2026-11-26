import request from 'supertest';
import { PrismaClient } from '@prisma/client';
import { createApp } from './app';

const prisma = new PrismaClient();
const app = createApp();

describe('Phase 2 workplace operating system', () => {
  let worksiteId = '';
  let organiserToken = '';
  let passengerToken = '';
  let circleId = '';
  let passengerProfileId = '';
  let messageId = '';

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
        name: 'Riverworks',
        slug: 'riverworks',
        domain: 'riverworks.example',
        allowedDomains: ['riverworks-partners.example'],
        invitationCode: 'RIVER-PILOT',
        verificationValidDays: 90,
        worksites: { create: { name: 'Quayside' } },
      },
      include: { worksites: true },
    });
    worksiteId = workplace.worksites[0].id;
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it('resolves invitation codes to workplace worksites', async () => {
    const response = await request(app)
      .post('/auth/redeem-invite')
      .send({ invitationCode: 'RIVER-PILOT' });
    expect(response.status).toBe(200);
    expect(response.body.workplace.worksites[0].id).toBe(worksiteId);
  });

  it('registers with invitation and renews domain verification', async () => {
    const organiser = await request(app).post('/auth/register').send({
      email: 'ops@riverworks.example',
      password: 'Password123!',
      firstName: 'Owen',
      initials: 'OW',
      worksiteId,
      homeArea: 'Digbeth',
      corridor: 'Digbeth to quayside',
      days: [1, 2, 3, 4, 5],
      arrivalMinutes: 510,
      departureMinutes: 1050,
      role: 'driver',
      availableSeats: 3,
      invitationCode: 'RIVER-PILOT',
    });
    expect(organiser.status).toBe(201);
    organiserToken = organiser.body.accessToken;

    const passenger = await request(app).post('/auth/register').send({
      email: 'pat@riverworks-partners.example',
      password: 'Password123!',
      firstName: 'Pat',
      initials: 'PA',
      worksiteId,
      homeArea: 'Digbeth',
      corridor: 'Digbeth to quayside',
      days: [1, 3, 5],
      arrivalMinutes: 520,
      departureMinutes: 1040,
      role: 'passenger',
      availableSeats: 0,
      invitationCode: 'RIVER-PILOT',
    });
    expect(passenger.status).toBe(201);
    passengerToken = passenger.body.accessToken;
    passengerProfileId = passenger.body.user.profile.id;

    const verified = await request(app)
      .post('/auth/verify-workplace')
      .set('Authorization', `Bearer ${passengerToken}`)
      .send({ email: 'pat@riverworks-partners.example' });
    expect(verified.status).toBe(200);
    expect(verified.body.verified).toBe(true);
    expect(verified.body.expiresAt).toBeTruthy();
  });

  it('supports organiser pause, seats, backup nomination and attendance summary', async () => {
    const migrated = await request(app)
      .post('/auth/migrate')
      .set('Authorization', `Bearer ${organiserToken}`)
      .send({
        circles: [{
          name: 'Digbeth Morning Circle',
          shiftLabel: 'Early',
          days: [1, 3, 5],
          departureWindow: '07:05-07:20',
          seats: 2,
        }],
      });
    expect(migrated.status).toBe(200);
    circleId = (await request(app)
      .get('/circles')
      .set('Authorization', `Bearer ${organiserToken}`)).body.circles[0].id;

    const join = await request(app)
      .post(`/circles/${circleId}/join`)
      .set('Authorization', `Bearer ${passengerToken}`)
      .send({ message: 'Same corridor' });
    expect(join.status).toBe(201);

    await request(app)
      .post(`/circles/${circleId}/accept`)
      .set('Authorization', `Bearer ${organiserToken}`)
      .send({ requestId: join.body.request.id });

    const seats = await request(app)
      .patch(`/circles/${circleId}`)
      .set('Authorization', `Bearer ${organiserToken}`)
      .send({ seats: 3 });
    expect(seats.status).toBe(200);
    expect(seats.body.circle.seats).toBe(3);

    const backup = await request(app)
      .post(`/circles/${circleId}/backup-driver`)
      .set('Authorization', `Bearer ${organiserToken}`)
      .send({ profileId: passengerProfileId });
    expect(backup.status).toBe(200);
    expect(backup.body.circle.backupDriverId).toBe(passengerProfileId);

    const paused = await request(app)
      .post(`/circles/${circleId}/pause`)
      .set('Authorization', `Bearer ${organiserToken}`);
    expect(paused.status).toBe(200);
    expect(paused.body.circle.state).toBe('paused');

    const resumed = await request(app)
      .post(`/circles/${circleId}/resume`)
      .set('Authorization', `Bearer ${organiserToken}`);
    expect(resumed.status).toBe(200);
    expect(['active', 'full']).toContain(resumed.body.circle.state);

    const summary = await request(app)
      .get(`/circles/${circleId}/attendance-summary`)
      .set('Authorization', `Bearer ${organiserToken}`);
    expect(summary.status).toBe(200);
    expect(Array.isArray(summary.body.summaries)).toBe(true);
  });

  it('supports secure circle messaging, reporting and corridor metrics', async () => {
    const sent = await request(app)
      .post(`/circles/${circleId}/messages`)
      .set('Authorization', `Bearer ${passengerToken}`)
      .set('Idempotency-Key', 'msg-1')
      .send({ body: 'Shall we meet by the station entrance?' });
    expect(sent.status).toBe(201);
    expect(sent.body.message.deliveryState).toBe('stored');
    messageId = sent.body.message.id;

    const listed = await request(app)
      .get(`/circles/${circleId}/messages`)
      .set('Authorization', `Bearer ${organiserToken}`);
    expect(listed.status).toBe(200);
    expect(listed.body.messages.length).toBe(1);

    const risky = await request(app)
      .post(`/circles/${circleId}/messages`)
      .set('Authorization', `Bearer ${organiserToken}`)
      .send({ body: 'Come to my house address tonight' });
    expect(risky.status).toBe(201);
    expect(risky.body.message.deliveryState).toBe('flagged');

    const report = await request(app)
      .post(`/messages/${messageId}/report`)
      .set('Authorization', `Bearer ${organiserToken}`)
      .send({ reason: 'Looks fine but testing report path' });
    expect(report.status).toBe(201);

    const prefs = await request(app)
      .patch('/auth/preferences')
      .set('Authorization', `Bearer ${passengerToken}`)
      .send({ quietHoursStart: 22 * 60, quietHoursEnd: 7 * 60 });
    expect(prefs.status).toBe(200);
    expect(prefs.body.quietHoursStart).toBe(22 * 60);

    const metrics = await request(app)
      .get('/metrics/efficiency')
      .set('Authorization', `Bearer ${organiserToken}`);
    expect(metrics.status).toBe(200);
    expect(metrics.body.metrics.corridorDensity[0].corridor).toBe('Digbeth to quayside');
  });
});
