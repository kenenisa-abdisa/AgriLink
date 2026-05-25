-- =============================================================================
-- AgriLink Ethiopia — MIGRATION Script (Safe to run on existing database)
-- Run this in Supabase Dashboard → SQL Editor
-- Updated: 2026-05-12
-- =============================================================================

-- ─── 1. Ensure base tables exist ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR UNIQUE NOT NULL,
  name VARCHAR NOT NULL,
  phone VARCHAR DEFAULT '',
  role VARCHAR DEFAULT 'buyer',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS farmers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  bio TEXT,
  rating FLOAT DEFAULT 0.0,
  total_reviews INT DEFAULT 0,
  certifications TEXT[] DEFAULT '{}',
  joined_date TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR NOT NULL,
  description TEXT,
  price FLOAT NOT NULL,
  unit VARCHAR NOT NULL,
  category VARCHAR NOT NULL,
  location VARCHAR NOT NULL,
  quantity FLOAT NOT NULL,
  is_organic BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id UUID REFERENCES users(id) ON DELETE CASCADE,
  farmer_id UUID REFERENCES farmers(id) ON DELETE CASCADE,
  total_amount FLOAT NOT NULL,
  status VARCHAR DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  quantity FLOAT NOT NULL,
  price FLOAT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
  receiver_id UUID REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── 2. Add missing columns to EXISTING tables ──────────────────────────────

-- Users: add missing columns
ALTER TABLE users ADD COLUMN IF NOT EXISTS region VARCHAR;
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_image VARCHAR;
ALTER TABLE users ADD COLUMN IF NOT EXISTS language VARCHAR DEFAULT 'en';

-- Farmers: add missing columns
ALTER TABLE farmers ADD COLUMN IF NOT EXISTS farm_name VARCHAR;
ALTER TABLE farmers ADD COLUMN IF NOT EXISTS region VARCHAR;
ALTER TABLE farmers ADD COLUMN IF NOT EXISTS town VARCHAR;
ALTER TABLE farmers ADD COLUMN IF NOT EXISTS farm_size FLOAT;
ALTER TABLE farmers ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE farmers ADD COLUMN IF NOT EXISTS payment_method VARCHAR;
ALTER TABLE farmers ADD COLUMN IF NOT EXISTS payment_number VARCHAR;

-- Products: add missing columns
ALTER TABLE products ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE products ADD COLUMN IF NOT EXISTS farmer_id UUID REFERENCES farmers(id) ON DELETE SET NULL;
ALTER TABLE products ADD COLUMN IF NOT EXISTS min_order FLOAT DEFAULT 1;
ALTER TABLE products ADD COLUMN IF NOT EXISTS delivery_available BOOLEAN DEFAULT TRUE;
ALTER TABLE products ADD COLUMN IF NOT EXISTS pickup_available BOOLEAN DEFAULT TRUE;
ALTER TABLE products ADD COLUMN IF NOT EXISTS bulk_available BOOLEAN DEFAULT FALSE;
ALTER TABLE products ADD COLUMN IF NOT EXISTS bulk_price FLOAT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS bulk_min_quantity FLOAT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS harvest_date TIMESTAMPTZ;
ALTER TABLE products ADD COLUMN IF NOT EXISTS image_urls TEXT[] DEFAULT '{}';
ALTER TABLE products ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';

-- Orders: add missing columns
ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_method VARCHAR;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_status VARCHAR DEFAULT 'pending';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_reference VARCHAR;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS paid_at TIMESTAMPTZ;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_address TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS is_bulk BOOLEAN DEFAULT FALSE;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS is_recurring BOOLEAN DEFAULT FALSE;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS recurrence_interval VARCHAR;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS confirmed_at TIMESTAMPTZ;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS dispatched_at TIMESTAMPTZ;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ;

-- Order Items: add missing columns
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS product_name VARCHAR;
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS unit VARCHAR;

-- ─── 3. Create NEW tables ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR NOT NULL,
  body TEXT,
  read BOOLEAN DEFAULT FALSE,
  data JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  buyer_id UUID REFERENCES users(id) ON DELETE CASCADE,
  farmer_id UUID REFERENCES farmers(id) ON DELETE CASCADE,
  rating FLOAT NOT NULL CHECK (rating >= 0 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(order_id, buyer_id)
);

CREATE TABLE IF NOT EXISTS withdrawals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id UUID REFERENCES farmers(id) ON DELETE CASCADE,
  amount FLOAT NOT NULL,
  fee FLOAT DEFAULT 0,
  net_amount FLOAT NOT NULL,
  method VARCHAR NOT NULL,
  account_number VARCHAR,
  status VARCHAR CHECK (status IN ('pending', 'completed', 'rejected')) DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  token TEXT UNIQUE NOT NULL,
  platform VARCHAR,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── 4. Enable Row Level Security ───────────────────────────────────────────

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE farmers ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE withdrawals ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

-- ─── 5. Drop old policies (safe — ignores if they don't exist) ──────────────

DO $$ BEGIN
  -- Old policies from the original schema
  DROP POLICY IF EXISTS "Allow anon select on products" ON products;
  DROP POLICY IF EXISTS "Allow anon select on farmers" ON farmers;
  DROP POLICY IF EXISTS "Allow anon select on users" ON users;
END $$;

-- ─── 6. Create RLS Policies (using CREATE OR REPLACE pattern) ───────────────

-- Public read access
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Anyone can view products' AND tablename = 'products') THEN
    CREATE POLICY "Anyone can view products" ON products FOR SELECT TO anon, authenticated USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Anyone can view farmers' AND tablename = 'farmers') THEN
    CREATE POLICY "Anyone can view farmers" ON farmers FOR SELECT TO anon, authenticated USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Anyone can view users' AND tablename = 'users') THEN
    CREATE POLICY "Anyone can view users" ON users FOR SELECT TO anon, authenticated USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Anyone can view reviews' AND tablename = 'reviews') THEN
    CREATE POLICY "Anyone can view reviews" ON reviews FOR SELECT TO anon, authenticated USING (true);
  END IF;
END $$;

-- Users policies
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can update own profile' AND tablename = 'users') THEN
    CREATE POLICY "Users can update own profile" ON users FOR UPDATE TO authenticated USING (auth.uid() = id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert own profile' AND tablename = 'users') THEN
    CREATE POLICY "Users can insert own profile" ON users FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
  END IF;
END $$;

-- Products policies
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert products' AND tablename = 'products') THEN
    CREATE POLICY "Users can insert products" ON products FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can update own products' AND tablename = 'products') THEN
    CREATE POLICY "Users can update own products" ON products FOR UPDATE TO authenticated USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can delete own products' AND tablename = 'products') THEN
    CREATE POLICY "Users can delete own products" ON products FOR DELETE TO authenticated USING (auth.uid() = user_id);
  END IF;
END $$;

-- Farmers policies
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert farmer profile' AND tablename = 'farmers') THEN
    CREATE POLICY "Users can insert farmer profile" ON farmers FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can update own farmer profile' AND tablename = 'farmers') THEN
    CREATE POLICY "Users can update own farmer profile" ON farmers FOR UPDATE TO authenticated USING (auth.uid() = user_id);
  END IF;
END $$;

-- Orders policies
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can view own orders' AND tablename = 'orders') THEN
    CREATE POLICY "Users can view own orders" ON orders FOR SELECT TO authenticated
    USING (auth.uid() = buyer_id OR farmer_id IN (SELECT id FROM farmers WHERE user_id = auth.uid()));
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert orders' AND tablename = 'orders') THEN
    CREATE POLICY "Users can insert orders" ON orders FOR INSERT TO authenticated WITH CHECK (auth.uid() = buyer_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Farmers can update order status' AND tablename = 'orders') THEN
    CREATE POLICY "Farmers can update order status" ON orders FOR UPDATE TO authenticated
    USING (farmer_id IN (SELECT id FROM farmers WHERE user_id = auth.uid()));
  END IF;
END $$;

-- Order items policies
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can view own order items' AND tablename = 'order_items') THEN
    CREATE POLICY "Users can view own order items" ON order_items FOR SELECT TO authenticated
    USING (order_id IN (SELECT id FROM orders WHERE buyer_id = auth.uid() OR farmer_id IN (SELECT id FROM farmers WHERE user_id = auth.uid())));
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert order items' AND tablename = 'order_items') THEN
    CREATE POLICY "Users can insert order items" ON order_items FOR INSERT TO authenticated WITH CHECK (true);
  END IF;
END $$;

-- Messages policies
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can view own messages' AND tablename = 'messages') THEN
    CREATE POLICY "Users can view own messages" ON messages FOR SELECT TO authenticated
    USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can send messages' AND tablename = 'messages') THEN
    CREATE POLICY "Users can send messages" ON messages FOR INSERT TO authenticated WITH CHECK (auth.uid() = sender_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can mark messages as read' AND tablename = 'messages') THEN
    CREATE POLICY "Users can mark messages as read" ON messages FOR UPDATE TO authenticated USING (auth.uid() = receiver_id);
  END IF;
END $$;

-- Notifications policies
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can view own notifications' AND tablename = 'notifications') THEN
    CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT TO authenticated USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can update own notifications' AND tablename = 'notifications') THEN
    CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE TO authenticated USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'System can insert notifications' AND tablename = 'notifications') THEN
    CREATE POLICY "System can insert notifications" ON notifications FOR INSERT TO authenticated WITH CHECK (true);
  END IF;
END $$;

-- Reviews policies
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert reviews' AND tablename = 'reviews') THEN
    CREATE POLICY "Users can insert reviews" ON reviews FOR INSERT TO authenticated WITH CHECK (auth.uid() = buyer_id);
  END IF;
END $$;

-- Withdrawals policies
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Farmers can view own withdrawals' AND tablename = 'withdrawals') THEN
    CREATE POLICY "Farmers can view own withdrawals" ON withdrawals FOR SELECT TO authenticated
    USING (farmer_id IN (SELECT id FROM farmers WHERE user_id = auth.uid()));
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Farmers can request withdrawals' AND tablename = 'withdrawals') THEN
    CREATE POLICY "Farmers can request withdrawals" ON withdrawals FOR INSERT TO authenticated
    WITH CHECK (farmer_id IN (SELECT id FROM farmers WHERE user_id = auth.uid()));
  END IF;
END $$;

-- Device tokens policies
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can manage own device tokens' AND tablename = 'device_tokens') THEN
    CREATE POLICY "Users can manage own device tokens" ON device_tokens FOR ALL TO authenticated USING (auth.uid() = user_id);
  END IF;
END $$;

-- ─── 7. Grants ──────────────────────────────────────────────────────────────

GRANT SELECT ON products TO anon;
GRANT SELECT ON farmers TO anon;
GRANT SELECT ON users TO anon;
GRANT SELECT ON reviews TO anon;

-- ─── 8. Enable Realtime ─────────────────────────────────────────────────────

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE products;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE orders;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE messages;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
