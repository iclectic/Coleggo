# Coleggo Backend

A production-readiness Node.js/Express/TypeScript API backed by PostgreSQL and Prisma.

## Stack

- **Runtime**: Node.js 20+
- **Framework**: Express 5
- **Language**: TypeScript 5
- **ORM**: Prisma 6
- **Database**: PostgreSQL 16
- **Auth**: bcrypt password hashing, 15-minute JWT access tokens, rotating refresh tokens

## Local setup

1. Copy environment variables:

```bash
cp .env.example .env
```

2. Start PostgreSQL (Docker Compose or a local Postgres 16 instance).

```bash
docker compose up -d
# or point DATABASE_URL at a local database
```

3. Install dependencies and generate the Prisma client:

```bash
npm install
npx prisma generate
```

4. Run migrations and seed data:

```bash
npx prisma migrate dev
npx prisma db seed
```

5. Run the server in development mode:

```bash
npm run dev
```

The API will be available at `http://localhost:3000`.

Seeded demo logins (development only):

- `asha@northstar.example` / `Password123!`
- `ben@northstar.example` / `Password123!`

## Useful commands

| Command | Purpose |
| --- | --- |
| `npm run dev` | Run with hot reload using `tsx` |
| `npm run build` | Compile TypeScript to `dist/` |
| `npm start` | Run compiled output |
| `npm test` | Run Jest unit + Phase 1 integration suite |
| `./scripts/demo_phase1.sh` | Live API walkthrough of the Phase 1 commute flow |
| `npm run db:migrate` | Apply Prisma migrations interactively |
| `npm run db:generate` | Regenerate Prisma client after schema changes |
| `npm run db:seed` | Run `prisma/seed.ts` directly |

## Environment variables

See `.env.example` for required values.

- `DATABASE_URL` - PostgreSQL connection string
- `JWT_SECRET` - Secret used to sign and verify JWTs. **Must be long and random in production.**
- `PORT` - Port the Express server binds to (default `3000`)
- `NODE_ENV` - `development` or `production`
- `CORS_ORIGIN` - Allowed web application origin. Required in production.
- `ALLOW_MANUAL_JOBS` - Set `true` to allow authenticated job triggers in production

## Security notes

- Access tokens expire after 15 minutes. Refresh tokens are hashed at rest and rotate on use.
- The API refuses to start in production without a unique `JWT_SECRET` of at least 32 characters and an explicit `CORS_ORIGIN`.
- The seed script creates mock users and should only be used in development.
- `bcrypt` is used for password hashing.
- Mutating journey/circle endpoints accept an `Idempotency-Key` header.

## API overview

| Route | Description |
| --- | --- |
| `POST /auth/register` | Create an account with a workplace profile |
| `POST /auth/login` | Authenticate and receive access + refresh tokens |
| `POST /auth/refresh` | Rotate refresh token and issue a new access token |
| `GET /auth/me` | Fetch the authenticated user and profile |
| `POST /auth/verify-workplace` | Verify workplace email domain (not driving fitness) |
| `POST /auth/redeem-invite` | Resolve an employer invitation code |
| `PATCH /auth/preferences` | Quiet hours preferences |
| `GET /workplaces` | List workplaces and worksites |
| `GET /matches` | Server-side explainable commute matches |
| `GET /reliability/me` | Behavioural reliability signals for the current user |
| `GET /metrics/efficiency` | Worksite fill / confirmation / backup aggregates |
| `POST /jobs/generate-journeys` | Generate upcoming journeys from active Circles |
| `POST /jobs/advance-confirmation-windows` | Open confirmation windows / mark missed journeys |
| `GET /circles` | List commute circles for the authenticated profile |
| `GET /circles/:id` | Get a single circle with members |
| `POST /circles/:id/join` | Request to join a circle |
| `POST /circles/:id/accept` | Accept a pending join request (organiser only) |
| `POST /circles/:id/decline` | Decline a pending join request (organiser only) |
| `POST /circles/:id/pause` | Pause a circle (organiser) |
| `POST /circles/:id/resume` | Resume a paused circle (organiser) |
| `PATCH /circles/:id` | Update seats or departure window (organiser) |
| `POST /circles/:id/backup-driver` | Nominate a backup driver (organiser) |
| `GET /circles/:id/attendance-summary` | Privacy-safe attendance counts |
| `POST /circles/:id/pause-participation` | Pause own membership |
| `POST /circles/:id/leave` | Leave a circle |
| `GET /circles/:id/messages` | List secure circle messages |
| `POST /circles/:id/messages` | Send a secure circle message |
| `POST /messages/:id/report` | Report a message for moderation |
| `GET /journeys/next` | Get the next upcoming journey |
| `POST /journeys/:id/confirm` | Confirm attendance for a journey |
| `POST /journeys/:id/cancel` | Cancel a journey and list backup candidates |
| `POST /journeys/:id/backup` | Create a replacement journey with a backup driver |
| `GET /notifications` | List notifications for the authenticated user |
| `POST /notifications/:id/read` | Mark one notification as read |
| `POST /notifications/read-all` | Mark all notifications as read |
| `GET /health` | Health check |
