-- CreateEnum
CREATE TYPE "MessageDeliveryState" AS ENUM ('stored', 'flagged', 'removed');

-- CreateEnum
CREATE TYPE "ModerationReportStatus" AS ENUM ('submitted', 'reviewed', 'dismissed');

-- AlterTable
ALTER TABLE "circle_memberships" ADD COLUMN     "paused" BOOLEAN NOT NULL DEFAULT false;

-- AlterTable
ALTER TABLE "commute_circles" ADD COLUMN     "backupDriverId" TEXT;

-- AlterTable
ALTER TABLE "profiles" ADD COLUMN     "quietHoursEnd" INTEGER,
ADD COLUMN     "quietHoursStart" INTEGER,
ADD COLUMN     "verifiedAt" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "workplaces" ADD COLUMN     "allowedDomains" TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN     "invitationCode" TEXT,
ADD COLUMN     "verificationValidDays" INTEGER NOT NULL DEFAULT 90;

-- CreateTable
CREATE TABLE "message_threads" (
    "id" TEXT NOT NULL,
    "circleId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "archived" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "message_threads_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "messages" (
    "id" TEXT NOT NULL,
    "threadId" TEXT NOT NULL,
    "senderProfileId" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "deliveryState" "MessageDeliveryState" NOT NULL DEFAULT 'stored',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "message_moderation_reports" (
    "id" TEXT NOT NULL,
    "messageId" TEXT NOT NULL,
    "reporterId" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "status" "ModerationReportStatus" NOT NULL DEFAULT 'submitted',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "message_moderation_reports_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "message_threads_circleId_key" ON "message_threads"("circleId");

-- CreateIndex
CREATE INDEX "messages_threadId_createdAt_idx" ON "messages"("threadId", "createdAt");

-- CreateIndex
CREATE INDEX "messages_senderProfileId_createdAt_idx" ON "messages"("senderProfileId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "message_moderation_reports_messageId_reporterId_key" ON "message_moderation_reports"("messageId", "reporterId");

-- CreateIndex
CREATE UNIQUE INDEX "workplaces_invitationCode_key" ON "workplaces"("invitationCode");

-- AddForeignKey
ALTER TABLE "message_threads" ADD CONSTRAINT "message_threads_circleId_fkey" FOREIGN KEY ("circleId") REFERENCES "commute_circles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_threadId_fkey" FOREIGN KEY ("threadId") REFERENCES "message_threads"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_senderProfileId_fkey" FOREIGN KEY ("senderProfileId") REFERENCES "profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_moderation_reports" ADD CONSTRAINT "message_moderation_reports_messageId_fkey" FOREIGN KEY ("messageId") REFERENCES "messages"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_moderation_reports" ADD CONSTRAINT "message_moderation_reports_reporterId_fkey" FOREIGN KEY ("reporterId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

