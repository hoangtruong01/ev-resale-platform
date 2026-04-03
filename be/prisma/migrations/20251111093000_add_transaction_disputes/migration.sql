-- CreateEnum
CREATE TYPE "public"."TransactionPartyRole" AS ENUM ('BUYER', 'SELLER');

-- CreateEnum
CREATE TYPE "public"."TransactionDisputeStatus" AS ENUM ('OPEN', 'IN_REVIEW', 'RESOLVED');

-- CreateEnum
CREATE TYPE "public"."TransactionDisputeResolution" AS ENUM ('BUYER', 'SELLER', 'PARTIAL');

-- CreateTable
CREATE TABLE "public"."transaction_disputes" (
    "id" TEXT NOT NULL,
    "transactionId" TEXT NOT NULL,
    "reporterId" TEXT NOT NULL,
    "reporterRole" "public"."TransactionPartyRole" NOT NULL,
    "reason" TEXT NOT NULL,
    "description" TEXT,
    "evidence" JSONB,
    "status" "public"."TransactionDisputeStatus" NOT NULL DEFAULT 'OPEN',
    "resolutionOutcome" "public"."TransactionDisputeResolution",
    "resolutionNotes" TEXT,
    "resolvedById" TEXT,
    "resolvedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "transaction_disputes_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "transaction_disputes_transactionId_key" UNIQUE ("transactionId")
);

-- CreateIndex
CREATE INDEX "transaction_disputes_status_idx" ON "public"."transaction_disputes"("status");

-- AddForeignKey
ALTER TABLE "public"."transaction_disputes"
  ADD CONSTRAINT "transaction_disputes_transactionId_fkey" FOREIGN KEY ("transactionId") REFERENCES "public"."transactions"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT "transaction_disputes_reporterId_fkey" FOREIGN KEY ("reporterId") REFERENCES "public"."users"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT "transaction_disputes_resolvedById_fkey" FOREIGN KEY ("resolvedById") REFERENCES "public"."users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
