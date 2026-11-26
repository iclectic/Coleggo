DO $$ BEGIN
  ALTER TYPE "ModerationReportStatus" ADD VALUE 'escalated';
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

ALTER TABLE "profiles" ADD COLUMN IF NOT EXISTS "postcodeDistrict" TEXT,
ADD COLUMN IF NOT EXISTS "approxLatitude" DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS "approxLongitude" DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS "privacyRadiusMetres" INTEGER DEFAULT 500;

ALTER TABLE "attendances" ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE "message_moderation_reports" ADD COLUMN IF NOT EXISTS "resolvedAt" TIMESTAMP(3);

CREATE TABLE IF NOT EXISTS "domain_events" (
    "id" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "actorUserId" TEXT,
    "subjectType" TEXT NOT NULL,
    "subjectId" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "domain_events_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "legal_holds" (
    "id" TEXT NOT NULL,
    "scope" TEXT NOT NULL,
    "subjectId" TEXT,
    "reason" TEXT NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "releasedAt" TIMESTAMP(3),
    CONSTRAINT "legal_holds_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "domain_events_type_createdAt_idx" ON "domain_events"("type", "createdAt");
CREATE INDEX IF NOT EXISTS "domain_events_subjectType_subjectId_idx" ON "domain_events"("subjectType", "subjectId");
CREATE INDEX IF NOT EXISTS "domain_events_actorUserId_createdAt_idx" ON "domain_events"("actorUserId", "createdAt");
CREATE INDEX IF NOT EXISTS "legal_holds_scope_subjectId_active_idx" ON "legal_holds"("scope", "subjectId", "active");
CREATE INDEX IF NOT EXISTS "message_moderation_reports_status_resolvedAt_idx" ON "message_moderation_reports"("status", "resolvedAt");
