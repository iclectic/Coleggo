# Staging deployment

The staging API is deployed with the production-targeted Compose file at `backend/docker-compose.staging.yml`. It runs PostgreSQL and a non-root API container on the staging host, applies committed Prisma migrations, and binds the API to loopback only. Put a TLS reverse proxy in front of `127.0.0.1:3000`.

## Prerequisites

- Docker Engine with Compose v2 on the staging host.
- A DNS name and TLS reverse proxy for the API.
- This repository checked out on the release branch.
- A secure method for storing the staging environment file outside Git.

## Initial setup

1. Copy the template and restrict its permissions:

```bash
cp backend/.env.staging.example backend/.env.staging
chmod 600 backend/.env.staging
```

2. Replace every placeholder. Generate separate random values for `POSTGRES_PASSWORD` and `JWT_SECRET`; `JWT_SECRET` must have at least 32 characters. URL-encode database-password characters that are not valid in a URL before adding them to `DATABASE_URL`.

3. Set `CORS_ORIGIN` to the exact browser origin that will use the staging API, including `https://` and no trailing path.

4. Start the stack:

```bash
docker compose --env-file backend/.env.staging -f backend/docker-compose.staging.yml up -d --build
```

The `migrate` service runs `prisma migrate deploy`. The API starts only after that service completes successfully.

## Deploy an update

```bash
git fetch origin
git checkout <approved-release-ref>
git pull --ff-only
docker compose --env-file backend/.env.staging -f backend/docker-compose.staging.yml up -d --build
docker compose --env-file backend/.env.staging -f backend/docker-compose.staging.yml ps
curl --fail --silent https://<staging-api-host>/health
```

Review the `migrate` service logs if the API does not start:

```bash
docker compose --env-file backend/.env.staging -f backend/docker-compose.staging.yml logs migrate
```

## Rollback

1. Stop the new application containers without deleting the database volume:

```bash
docker compose --env-file backend/.env.staging -f backend/docker-compose.staging.yml down
```

2. Check out the previously deployed Git revision and start it with the same command used for deployment.

3. Validate `/health` and the core authentication, circle, journey, and notification flows.

Do not use `docker compose down --volumes` in staging. Prisma migrations are forward-only in this workflow. If a migration introduces an application problem, deploy a forward corrective migration rather than modifying the production schema manually.

## CI and release gate

GitHub Actions runs backend type checks and Jest tests when `backend/**` changes, and Flutter analysis and widget tests when client code changes. Require both checks before deploying an approved branch. The actual host deployment remains manual until a hosting provider and secret-management integration are selected.
