/*
  Warnings:

  - A unique constraint covering the columns `[facebookId]` on the table `users` will be added. If there are existing duplicate values, this will fail.

*/
-- AlterTable
ALTER TABLE "public"."users" ADD COLUMN     "facebookId" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "users_facebookId_key" ON "public"."users"("facebookId");
