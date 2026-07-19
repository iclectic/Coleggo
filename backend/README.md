# Coleggo Backend

A production-readiness Node.js/Express/TypeScript API backed by PostgreSQL and Prisma.

## Stack

- **Runtime**: Node.js 20+
- **Framework**: Express 5
- **Language**: TypeScript 5
- **ORM**: Prisma 6
- **Database**: PostgreSQL 16
- **Auth**: bcrypt password hashing + JWT access tokens

## Local setup

1. Copy environment variables:

```bash
cp .env.example .env
```

2. Start PostgreSQL:

```bash
docker-compose up -d
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

## Useful commands

| Command | Purpose |
| --- | --- |
| `npm run dev` | Run with hot reload using `tsx` |
| `npm run build` | Compile TypeScript to `dist/` |
| `npm start` | Run compiled output |
| `npm test` | Run Jest test suite |
| `npm run db:migrate` | Apply Prisma migrations interactively |
| `npm run db:generate` | Regenerate Prisma client after schema changes |
| `npm run db:seed` | Run `prisma/seed.ts` directly |

## Environment variables

See `.env.example` for required values.

- `DATABASE_URL` - PostgreSQL connection string
- `JWT_SECRET` - Secret used to sign and verify JWTs. **Must be long and random in production.**
- `PORT` - Port the Express server binds to (default `3000`)
- `NODE_ENV` - `development` or `production`

## Security notes

- JWTs expire after 7 days in development. Reduce this in production.
- The seed script creates mock users and should only be used in development.
- `bcrypt` is used for password hashing.
- CORS is enabled for all origins in development. Restrict this for staging and production.

## API overview

| Route | Description |
| --- | --- |
| `POST /auth/register` | Create an account with a workplace profile |
| `POST /auth/login` | Authenticate and receive a JWT |
| `GET /auth/me` | Fetch the authenticated user and profile |
| `POST /auth/verify-workplace` | Start mock workplace email verification |
| `GET /circles` | List commute circles for the authenticated profile |
| `GET /circles/:id` | Get a single circle with members |
| `POST /circles/:id/join` | Request to join a circle |
| `POST /circles/:id/accept` | Accept a pending join request (organiser only) |
| `POST /circles/:id/decline` | Decline a pending join request (organiser only) |
| `GET /journeys/next` | Get the next upcoming journey |
| `POST /journeys/:id/confirm` | Confirm attendance for a journey |
| `POST /journeys/:id/cancel` | Cancel a journey (driver/organiser only) |
| `GET /notifications` | List notifications for the authenticated user |
| `POST /notifications/:id/read` | Mark one notification as read |
| `POST /notifications/read-all` | Mark all notifications as read |
| `GET /health` | Health check |
