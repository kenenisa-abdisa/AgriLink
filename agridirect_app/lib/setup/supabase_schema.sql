-- =============================================================================
-- AgriLink Ethiopia — Complete Supabase Schema
-- Updated: 2026-05-12
-- =============================================================================

-- ─── Users ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR UNIQUE NOT NULL,
  name VARCHAR NOT NULL,
  phone VARCHAR DEFAULT '',
  role VARCHAR CHECK (role IN ('farmer', 'buyer', 'business', 'admin')) DEFAULT 'buyer',
  region VARCHAR,
  profile_image VARCHAR,
  language VARCHAR DEFAULT 'en',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Farmers ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS farmers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  farm_name VARCHAR,
  bio TEXT,
  region VARCHAR,
  town VARCHAR,
  farm_size FLOAT,
  rating FLOAT DEFAULT 0.0,
  total_reviews INT DEFAULT 0,
  certifications TEXT[] DEFAULT '{}',
  is_verified BOOLEAN DEFAULT FALSE,
  payment_method VARCHAR,
  payment_number VARCHAR,
  joined_date TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Products ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  farmer_id UUID REFERENCES farmers(id) ON DELETE SET NULL,
  name VARCHAR NOT NULL,
  description TEXT,
  price FLOAT NOT NULL,
  unit VARCHAR NOT NULL,
  category VARCHAR NOT NULL,
  location VARCHAR NOT NULL,
  quantity FLOAT NOT NULL,
  min_order FLOAT DEFAULT 1,
  is_organic BOOLEAN DEFAULT FALSE,
  delivery_available BOOLEAN DEFAULT TRUE,
  pickup_available BOOLEAN DEFAULT TRUE,
  bulk_available BOOLEAN DEFAULT FALSE,
  bulk_price FLOAT,
  bulk_min_quantity FLOAT,
  harvest_date TIMESTAMPTZ,
  image_urls TEXT[] DEFAULT '{}',
  tags TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Orders ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id UUID REFERENCES users(id) ON DELETE CASCADE,
  farmer_id UUID REFERENCES farmers(id) ON DELETE CASCADE,
  total_amount FLOAT NOT NULL,
  status VARCHAR CHECK (status IN (
    'pending', 'confirmed', 'dispatched', 'delivered', 'cancelled',
    'quote_requested', 'quote_sent'
  )) DEFAULT 'pending',
  payment_method VARCHAR,
  payment_status VARCHAR DEFAULT 'pending',
  payment_reference VARCHAR,
  paid_at TIMESTAMPTZ,
  delivery_address TEXT,
  notes TEXT,
  is_bulk BOOLEAN DEFAULT FALSE,
  is_recurring BOOLEAN DEFAULT FALSE,
  recurrence_interval VARCHAR,
  confirmed_at TIMESTAMPTZ,
  dispatched_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Order Items ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  product_name VARCHAR,
  quantity FLOAT NOT NULL,
  unit VARCHAR,
  price FLOAT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Messages ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
  receiver_id UUID REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Notifications ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR NOT NULL,
  body TEXT,
  read BOOLEAN DEFAULT FALSE,
  data JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Reviews ─────────────────────────────────────────────────────────────────
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

-- ─── Withdrawals ─────────────────────────────────────────────────────────────
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

-- ─── Device Tokens (FCM) ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  token TEXT UNIQUE NOT NULL,
  platform VARCHAR,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- Row Level Security (RLS)
-- =============================================================================
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

-- ─── Public read access ──────────────────────────────────────────────────────
CREATE POLICY "Anyone can view products"
  ON products FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "Anyone can view farmers"
  ON farmers FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "Anyone can view users"
  ON users FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "Anyone can view reviews"
  ON reviews FOR SELECT TO anon, authenticated USING (true);

-- ─── Authenticated user policies ─────────────────────────────────────────────

-- Users: can update own row
CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON users FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id);

-- Products: owners can manage
CREATE POLICY "Users can insert products"
  ON products FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own products"
  ON products FOR UPDATE TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own products"
  ON products FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- Farmers: owner can manage
CREATE POLICY "Users can insert farmer profile"
  ON farmers FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own farmer profile"
  ON farmers FOR UPDATE TO authenticated
  USING (auth.uid() = user_id);

-- Orders: buyer or farmer can view their orders
CREATE POLICY "Users can view own orders"
  ON orders FOR SELECT TO authenticated
  USING (
    auth.uid() = buyer_id OR
    farmer_id IN (SELECT id FROM farmers WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can insert orders"
  ON orders FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = buyer_id);

CREATE POLICY "Farmers can update order status"
  ON orders FOR UPDATE TO authenticated
  USING (
    farmer_id IN (SELECT id FROM farmers WHERE user_id = auth.uid())
  );

-- Order items: same access as parent order
CREATE POLICY "Users can view own order items"
  ON order_items FOR SELECT TO authenticated
  USING (
    order_id IN (SELECT id FROM orders WHERE
      buyer_id = auth.uid() OR
      farmer_id IN (SELECT id FROM farmers WHERE user_id = auth.uid())
    )
  );

CREATE POLICY "Users can insert order items"
  ON order_items FOR INSERT TO authenticated
  WITH CHECK (true);

-- Messages: sender or receiver can view
CREATE POLICY "Users can view own messages"
  ON messages FOR SELECT TO authenticated
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can send messages"
  ON messages FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can mark messages as read"
  ON messages FOR UPDATE TO authenticated
  USING (auth.uid() = receiver_id);

CREATE POLICY "Users can edit own messages"
  ON messages FOR UPDATE TO authenticated
  USING (auth.uid() = sender_id);

CREATE POLICY "Users can delete own messages"
  ON messages FOR DELETE TO authenticated
  USING (auth.uid() = sender_id);

-- Notifications: own notifications only
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications"
  ON notifications FOR INSERT TO authenticated
  WITH CHECK (true);

-- Reviews: anyone reads, buyers write
CREATE POLICY "Users can insert reviews"
  ON reviews FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = buyer_id);

-- Withdrawals: farmer can view and insert own
CREATE POLICY "Farmers can view own withdrawals"
  ON withdrawals FOR SELECT TO authenticated
  USING (
    farmer_id IN (SELECT id FROM farmers WHERE user_id = auth.uid())
  );

CREATE POLICY "Farmers can request withdrawals"
  ON withdrawals FOR INSERT TO authenticated
  WITH CHECK (
    farmer_id IN (SELECT id FROM farmers WHERE user_id = auth.uid())
  );

-- Device Tokens: own tokens only
CREATE POLICY "Users can manage own device tokens"
  ON device_tokens FOR ALL TO authenticated
  USING (auth.uid() = user_id);

-- =============================================================================
-- Grants
-- =============================================================================
GRANT SELECT ON products TO anon;
GRANT SELECT ON farmers TO anon;
GRANT SELECT ON users TO anon;
GRANT SELECT ON reviews TO anon;

-- ─── Realtime ────────────────────────────────────────────────────────────────
-- Enable realtime for tables that use .stream() in the app
ALTER PUBLICATION supabase_realtime ADD TABLE products;
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
