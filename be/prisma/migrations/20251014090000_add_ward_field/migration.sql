-- Add ward column to profiles for finer-grained address segmentation
ALTER TABLE "public"."profiles"
ADD COLUMN IF NOT EXISTS "ward" TEXT;
