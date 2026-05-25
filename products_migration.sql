-- ============================================================
-- AgriLink: Complete products table migration
-- Run this in Supabase SQL Editor to add all missing columns
-- ============================================================

ALTER TABLE products
  ADD COLUMN IF NOT EXISTS farmer_id          UUID         REFERENCES farmers(id),
  ADD COLUMN IF NOT EXISTS description        TEXT,
  ADD COLUMN IF NOT EXISTS unit               TEXT         NOT NULL DEFAULT 'kg',
  ADD COLUMN IF NOT EXISTS category           TEXT         NOT NULL DEFAULT 'Other',
  ADD COLUMN IF NOT EXISTS location           TEXT         NOT NULL DEFAULT 'Ethiopia',
  ADD COLUMN IF NOT EXISTS quantity           NUMERIC      NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS min_order          NUMERIC      NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS is_organic         BOOLEAN      NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS delivery_available BOOLEAN      NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS pickup_available   BOOLEAN      NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS bulk_available     BOOLEAN      NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS bulk_price         NUMERIC,
  ADD COLUMN IF NOT EXISTS bulk_min_quantity  NUMERIC,
  ADD COLUMN IF NOT EXISTS image_urls         TEXT[]       NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS tags               TEXT[]       NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS harvest_date       TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS created_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW();

-- Force PostgREST to reload its schema cache immediately
NOTIFY pgrst, 'reload schema';
