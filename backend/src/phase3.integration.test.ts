import request from 'supertest';
import { PrismaClient } from '@prisma/client';
import { createApp } from './app';
import { resetRateLimits } from './lib/rateLimit';
import { resetRequestSamples } from './lib/requestMetrics';

const prisma = new PrismaClient();
const app = createApp();

describe('Phase 3 hard reliability', () => {
  let worksiteId = '';
  let organiserToken = '';
  let passengerToken = '';
  let passengerUserId = '';
  let circleId = '';
  let journeyId = '';
  let messageId = '';
  let reportId = '';

  beforeAll(async () => {
    resetRateLimits();
    resetRequestSamples();
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
        name: 'Audit Works',
        slug: 'audit-works',
        domain: 'auditworks.example',
        invitationCode: 'AUDIT-PILOT',
        worksites: { create: { name: 'Dockside' } },
      },
      include: { worksites: true },
    });
    worksiteId = workplace.worksites[0].id;
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it('registers users with approximate corridor fields and builds a circle', async () => {
    const organiser = await request(app).post('/auth/register').send({
      email: 'ops@auditworks.example',
      password: 'Password123!',
      firstName: 'Owen',
      initials: 'OW',
      worksiteId,
      homeArea: 'Digbeth',
      corridor: 'Digbeth to dockside',
      postcodeDistrict: 'B5',
      approxLatitude: 52.475,
      approxLongitude: -1.885,
      days: [1, 2, 3, 4, 5],
      arrivalMinutes: 510,
      departureMinutes: 1050,
      role: 'driver',
      availableSeats: 3,
      invitationCode: 'AUDIT-PILOT',
    });
    expect(organiser.status).toBe(201);
    organiserToken = organiser.body.accessToken;

    const passenger = await request(app).post('/auth/register').send({
      email: 'pat@auditworks.example',
      password: 'Password123!',
      firstName: 'Pat',
      initials: 'PA',
      worksiteId,
      homeArea: 'Deritend',
      corridor: 'Digbeth to dockside',
      postcodeDistrict: 'B5',
      approxLatitude: 52.476,
      approxLongitude: -1.884,
      days: [2, 4],
      arrivalMinutes: 520,
      departureMinutes: 1040,
      role: 'passenger',
      availableSeats: 0,
      invitationCode: 'AUDIT-PILOT',
    });
    expect(passenger.status).toBe(201);
    passengerToken = passenger.body.accessToken;
    passengerUserId = passenger.body.user.id;

    await request(app)
      .post('/auth/migrate')
      .set('Authorization', `Bearer ${organiserToken}`)
      .send({
        circles: [{
          name: 'Dockside Evening Circle',
          shiftLabel: 'Late',
          days: [1, 3, 5],
          departureWindow: '17:30-18:00',
          seats: 1,
        }],
      });

    circleId = (await request(app)
      .get('/circles')
      .set('Authorization', `Bearer ${organiserToken}`)).body.circles[0].id;

    const join = await request(app)
      .post(`/circles/${circleId}/join`)
      .set('Authorization', `Bearer ${passengerToken}`)
      .send({ message: 'Same district' });
    expect(join.status).toBe(201);

    await request(app)
      .post(`/circles/${circleId}/accept`)
      .set('Authorization', `Bearer ${organiserToken}`)
      .send({ requestId: join.body.request.id });

    await request(app)
      .post('/jobs/generate-journeys')
      .set('Authorization', `Bearer ${organiserToken}`);
    await request(app)
      .post('/jobs/advance-confirmation-windows')
      .set('Authorization', `Bearer ${organiserToken}`);

    const next = await request(app)
      .get('/journeys/next')
      .set('Authorization', `Bearer ${passengerToken}`);
    expect(next.status).toBe(200);
    journeyId = next.body.journey.id;
  });

  it('audits confirm, cancel, message report and moderation escalation', async () => {
    const confirm = await request(app)
      .post(`/journeys/${journeyId}/confirm`)
      .set('Authorization', `Bearer ${passengerToken}`)
      .set('Idempotency-Key', 'p3-confirm-1')
      .send({ status: 'travelling' });
    expect(confirm.status).toBe(200);

    const cancel = await request(app)
      .post(`/journeys/${journeyId}/cancel`)
      .set('Authorization', `Bearer ${organiserToken}`)
      .set('Idempotency-Key', 'p3-cancel-1')
      .send({ reason: 'Vehicle unavailable' });
    expect(cancel.status).toBe(200);

    const sent = await request(app)
      .post(`/circles/${circleId}/messages`)
      .set('Authorization', `Bearer ${passengerToken}`)
      .send({ body: 'Thanks for arranging a backup.' });
    expect(sent.status).toBe(201);
    messageId = sent.body.message.id;

    const report = await request(app)
      .post(`/messages/${messageId}/report`)
      .set('Authorization', `Bearer ${organiserToken}`)
      .send({ reason: 'Testing escalation path' });
    expect(report.status).toBe(201);
    reportId = report.body.report.id;

    const escalated = await request(app)
      .patch(`/moderation/reports/${reportId}`)
      .set('Authorization', `Bearer ${organiserToken}`)
      .set('Idempotency-Key', 'p3-escalate-1')
      .send({ status: 'escalated', note: 'Needs human review' });
    expect(escalated.status).toBe(200);
    expect(escalated.body.report.status).toBe('escalated');

    const events = await request(app)
      .get('/metrics/audit-events')
      .set('Authorization', `Bearer ${organiserToken}`);
    expect(events.status).toBe(200);
    const types = events.body.events.map((event: { type: string }) => event.type);
    expect(types).toEqual(expect.arrayContaining([
      'journey.cancelled',
      'moderation.reported',
      'moderation.escalated',
      'membership.accepted',
    ]));
  });

  it('exposes capacity hints, SLO snapshot and data export', async () => {
    const efficiency = await request(app)
      .get('/metrics/efficiency')
      .set('Authorization', `Bearer ${organiserToken}`);
    expect(efficiency.status).toBe(200);
    expect(Array.isArray(efficiency.body.metrics.capacityHints)).toBe(true);
    expect(efficiency.body.metrics.capacityHints[0].underServedDays).toEqual(
      expect.arrayContaining([2, 4]),
    );

    const slo = await request(app)
      .get('/metrics/slo')
      .set('Authorization', `Bearer ${organiserToken}`);
    expect(slo.status).toBe(200);
    expect(slo.body.slo.requestCount).toBeGreaterThan(0);

    const exported = await request(app)
      .get('/auth/export')
      .set('Authorization', `Bearer ${passengerToken}`);
    expect(exported.status).toBe(200);
    expect(exported.body.user.email).toBe('pat@auditworks.example');
    expect(exported.body.user.profile.postcodeDistrict).toBe('B5');
    expect(Array.isArray(exported.body.auditEvents)).toBe(true);
  });

  it('blocks account deletion under legal hold and applies retention', async () => {
    await prisma.legalHold.create({
      data: {
        scope: 'user',
        subjectId: passengerUserId,
        reason: 'Safety investigation',
        active: true,
      },
    });

    const blocked = await request(app)
      .delete('/auth/account')
      .set('Authorization', `Bearer ${passengerToken}`);
    expect(blocked.status).toBe(423);

    const retention = await request(app)
      .post('/jobs/apply-retention')
      .set('Authorization', `Bearer ${organiserToken}`);
    expect(retention.status).toBe(200);
    expect(retention.body).toHaveProperty('reportsPurged');
    expect(retention.body).toHaveProperty('idempotencyPurged');
  });
});
