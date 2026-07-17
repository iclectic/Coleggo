---
title: "feat: Production-readiness slice for Coleggo"
type: feat
date: 2026-07-17
---

# feat: Production-readiness slice for Coleggo

## Summary

Move Coleggo from a local-only prototype to a server-backed P1 product with secure authentication, real workplace verification, backend-persisted Commute Circles, and a clear migration path from the existing `SharedPreferences` prototype state.

## P1 scope

### In scope

- Secure sign-up and login with email/password and JWT sessions.
- Workplace email-domain verification with a simulated approval flow.
- Server-side persistence for users, profiles, workplaces, worksites, Commute Circles, memberships, commute requests, journey occurrences, attendance, cancellations, reliability summaries and in-app notifications.
- REST API for the Flutter client with typed contracts and clear error responses.
- Backend-backed Commute Circle discovery, join request, acceptance and member list.
- Push-notification-ready local notification records for circle requests, journey confirmations, cancellations and backup-driver changes.
- Migration path from local `AppState` schema v4 to the new server-backed state.
- Hardened Flutter client that consumes the backend API behind repository interfaces.

### Out of scope for P1

- Real-time messaging infrastructure (secure post-acceptance messaging stays a placeholder).
- Real push notifications (app keeps local notification records; push delivery is P2).
- Payments, fares and driver earnings.
- Live location tracking, route calculation and maps.
- Employer admin dashboards and invitation codes.
- Production analytics, crash reporting and feature flags.
- Account deletion/export workflows beyond API endpoints.

## Stack decisions

- **Backend runtime:** Node.js with Express and TypeScript.
- **Database:** PostgreSQL with Prisma ORM.
- **Authentication:** bcrypt password hashing and signed JWT access tokens.
- **HTTP client:** `dio` in the Flutter app.
- **State management:** Riverpod with async repository results.
- **Hosting target:** Render or Railway for P1; documented for portability.

## Server data model

### Entities

- `User`: id, email, passwordHash, createdAt, updatedAt.
- `Workplace`: id, name, slug, domain, createdAt.
- `Worksite`: id, workplaceId, name, createdAt.
- `Profile`: id, userId, worksiteId, firstName, initials, role, homeArea, corridor, days, arrivalMinutes, departureMinutes, availableSeats, vehicleSummary.
- `CommuteCircle`: id, worksiteId, name, shiftLabel, days, departureWindow, seats, state, createdAt.
- `CircleMembership`: id, circleId, userId, role, joinedAt.
- `CommuteRequest`: id, circleId, requesterId, type, status, message, createdAt.
- `JourneyOccurrence`: id, circleId, scheduledFor, state, driverId.
- `Attendance`: id, journeyId, userId, status.
- `CancellationRecord`: id, journeyId, cancelledBy, reason, affectedPassengers, createdAt.
- `Notification`: id, userId, type, title, body, read, createdAt.

## API contracts

### Authentication

- `POST /auth/register` — create user and profile.
- `POST /auth/login` — return JWT.
- `GET /auth/me` — return current user and profile.
- `POST /auth/verify-workplace` — submit workplace email; simulate approval.

### Circles

- `GET /circles` — discover active circles for the user's worksite.
- `GET /circles/:id` — circle details with member list and membership status.
- `POST /circles/:id/join` — request to join.
- `POST /circles/:id/accept` — accept a pending join request.
- `POST /circles/:id/decline` — decline a pending join request.

### Journeys

- `GET /journeys/next` — next upcoming journey for the active circle.
- `POST /journeys/:id/confirm` — confirm attendance.
- `POST /journeys/:id/cancel` — cancel occurrence and suggest backups.
- `POST /journeys/:id/backup` — select backup driver.

### Notifications

- `GET /notifications` — list in-app notifications.
- `POST /notifications/:id/read` — mark as read.

## Security and privacy boundaries

- Passwords are bcrypt-hashed; plain passwords are never logged.
- JWT secrets are environment variables, not committed.
- Workplace verification is simulated with a clear boundary statement; it does not confirm driving ability, insurance, criminal history or character.
- Location display continues to use approximate area, postcode district and broad corridor; exact addresses and precise coordinates are not stored or returned.
- Messages are not implemented in P1, so no message storage risk exists.
- All endpoints require authentication except registration and login.

## Migration strategy

- Existing local `AppState` v4 can be uploaded once on first launch after the user logs in.
- The server creates profile, circles and memberships from the local snapshot if no server state exists.
- After migration the app uses server state; local state becomes a cache only.

## Pilot metrics

- 5 active Commute Circles formed within two weeks of beta launch.
- 80% of created journeys receive at least one confirmation.
- Zero unhandled server errors in the first 100 API calls per user.

## Verification

- `npm install`, `npx prisma migrate dev`, `npm run test` and `npm run dev` succeed.
- `flutter pub get`, `flutter analyze`, `flutter test` and `flutter build apk --debug` succeed.
- Integration tests cover registration, login, circle discovery, join request, acceptance, journey confirmation and cancellation backup.
