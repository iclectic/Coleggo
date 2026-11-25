-- CreateEnum
CREATE TYPE "CircleState" AS ENUM ('forming', 'active', 'full', 'paused', 'archived');

-- CreateEnum
CREATE TYPE "JourneyState" AS ENUM ('scheduled', 'awaitingConfirmation', 'confirmed', 'completed', 'cancelled', 'missed', 'archived');

-- CreateEnum
CREATE TYPE "RequestStatus" AS ENUM ('pending', 'accepted', 'declined', 'cancelled', 'expired');

-- CreateEnum
CREATE TYPE "MembershipRole" AS ENUM ('organiser', 'driver', 'passenger', 'backupDriver');

-- CreateEnum
CREATE TYPE "CommuteRole" AS ENUM ('driver', 'passenger', 'both');

-- CreateEnum
CREATE TYPE "AttendanceStatus" AS ENUM ('travelling', 'notTravelling', 'unsure');

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "refresh_tokens" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "tokenHash" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "revokedAt" TIMESTAMP(3),

    CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "workplaces" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "domain" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "workplaces_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "worksites" (
    "id" TEXT NOT NULL,
    "workplaceId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "worksites_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "profiles" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "worksiteId" TEXT NOT NULL,
    "firstName" TEXT NOT NULL,
    "initials" TEXT NOT NULL,
    "role" "CommuteRole" NOT NULL,
    "homeArea" TEXT NOT NULL,
    "corridor" TEXT NOT NULL,
    "days" INTEGER[],
    "arrivalMinutes" INTEGER NOT NULL,
    "departureMinutes" INTEGER NOT NULL,
    "availableSeats" INTEGER NOT NULL DEFAULT 0,
    "vehicleSummary" TEXT,
    "workplaceVerified" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "profiles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commute_circles" (
    "id" TEXT NOT NULL,
    "worksiteId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "shiftLabel" TEXT NOT NULL,
    "days" INTEGER[],
    "departureWindow" TEXT NOT NULL,
    "seats" INTEGER NOT NULL,
    "state" "CircleState" NOT NULL DEFAULT 'active',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "commute_circles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "circle_memberships" (
    "id" TEXT NOT NULL,
    "circleId" TEXT NOT NULL,
    "profileId" TEXT NOT NULL,
    "role" "MembershipRole" NOT NULL,
    "joinedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "circle_memberships_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "commute_requests" (
    "id" TEXT NOT NULL,
    "circleId" TEXT NOT NULL,
    "requesterId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "status" "RequestStatus" NOT NULL DEFAULT 'pending',
    "message" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "commute_requests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "journey_occurrences" (
    "id" TEXT NOT NULL,
    "circleId" TEXT NOT NULL,
    "scheduledFor" TIMESTAMP(3) NOT NULL,
    "state" "JourneyState" NOT NULL DEFAULT 'scheduled',
    "driverId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "journey_occurrences_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "attendances" (
    "id" TEXT NOT NULL,
    "journeyId" TEXT NOT NULL,
    "profileId" TEXT NOT NULL,
    "status" "AttendanceStatus" NOT NULL,

    CONSTRAINT "attendances_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cancellation_records" (
    "id" TEXT NOT NULL,
    "journeyId" TEXT NOT NULL,
    "cancelledById" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "affectedPassengers" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "cancellation_records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "read" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "idempotency_keys" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "method" TEXT NOT NULL,
    "path" TEXT NOT NULL,
    "statusCode" INTEGER NOT NULL,
    "responseBody" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "idempotency_keys_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "refresh_tokens_tokenHash_key" ON "refresh_tokens"("tokenHash");

-- CreateIndex
CREATE INDEX "refresh_tokens_userId_idx" ON "refresh_tokens"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "workplaces_slug_key" ON "workplaces"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "workplaces_domain_key" ON "workplaces"("domain");

-- CreateIndex
CREATE UNIQUE INDEX "worksites_workplaceId_name_key" ON "worksites"("workplaceId", "name");

-- CreateIndex
CREATE UNIQUE INDEX "profiles_userId_key" ON "profiles"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "circle_memberships_circleId_profileId_key" ON "circle_memberships"("circleId", "profileId");

-- CreateIndex
CREATE INDEX "journey_occurrences_state_scheduledFor_idx" ON "journey_occurrences"("state", "scheduledFor");

-- CreateIndex
CREATE UNIQUE INDEX "journey_occurrences_circleId_scheduledFor_key" ON "journey_occurrences"("circleId", "scheduledFor");

-- CreateIndex
CREATE UNIQUE INDEX "attendances_journeyId_profileId_key" ON "attendances"("journeyId", "profileId");

-- CreateIndex
CREATE UNIQUE INDEX "idempotency_keys_userId_key_method_path_key" ON "idempotency_keys"("userId", "key", "method", "path");

-- AddForeignKey
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "worksites" ADD CONSTRAINT "worksites_workplaceId_fkey" FOREIGN KEY ("workplaceId") REFERENCES "workplaces"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "profiles" ADD CONSTRAINT "profiles_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "profiles" ADD CONSTRAINT "profiles_worksiteId_fkey" FOREIGN KEY ("worksiteId") REFERENCES "worksites"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commute_circles" ADD CONSTRAINT "commute_circles_worksiteId_fkey" FOREIGN KEY ("worksiteId") REFERENCES "worksites"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "circle_memberships" ADD CONSTRAINT "circle_memberships_circleId_fkey" FOREIGN KEY ("circleId") REFERENCES "commute_circles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "circle_memberships" ADD CONSTRAINT "circle_memberships_profileId_fkey" FOREIGN KEY ("profileId") REFERENCES "profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commute_requests" ADD CONSTRAINT "commute_requests_circleId_fkey" FOREIGN KEY ("circleId") REFERENCES "commute_circles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commute_requests" ADD CONSTRAINT "commute_requests_requesterId_fkey" FOREIGN KEY ("requesterId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "journey_occurrences" ADD CONSTRAINT "journey_occurrences_circleId_fkey" FOREIGN KEY ("circleId") REFERENCES "commute_circles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "attendances" ADD CONSTRAINT "attendances_journeyId_fkey" FOREIGN KEY ("journeyId") REFERENCES "journey_occurrences"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "attendances" ADD CONSTRAINT "attendances_profileId_fkey" FOREIGN KEY ("profileId") REFERENCES "profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cancellation_records" ADD CONSTRAINT "cancellation_records_journeyId_fkey" FOREIGN KEY ("journeyId") REFERENCES "journey_occurrences"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cancellation_records" ADD CONSTRAINT "cancellation_records_cancelledById_fkey" FOREIGN KEY ("cancelledById") REFERENCES "profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
