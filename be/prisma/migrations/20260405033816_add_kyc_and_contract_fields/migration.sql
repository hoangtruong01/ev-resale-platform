-- CreateEnum
CREATE TYPE "public"."KycStatus" AS ENUM ('UNVERIFIED', 'PENDING', 'APPROVED', 'REJECTED');

-- AlterTable
ALTER TABLE "public"."profiles" ADD COLUMN     "faceImage" TEXT,
ADD COLUMN     "idBackImage" TEXT,
ADD COLUMN     "idFrontImage" TEXT,
ADD COLUMN     "idIssueDate" TIMESTAMP(3),
ADD COLUMN     "idIssuePlace" TEXT,
ADD COLUMN     "kycStatus" "public"."KycStatus" NOT NULL DEFAULT 'UNVERIFIED';
