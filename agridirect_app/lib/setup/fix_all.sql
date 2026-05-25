-- ═══════════════════════════════════════════════════════════════
-- AgriLink — ONE-SHOT FIX (paste this entire block and click Run)
-- Safe: won't delete or overwrite any existing data
-- ═══════════════════════════════════════════════════════════════

-- ── TABLES ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), email VARCHAR UNIQUE NOT NULL, name VARCHAR NOT NULL, phone VARCHAR DEFAULT '', role VARCHAR DEFAULT 'buyer', created_at TIMESTAMPTZ DEFAULT NOW());
CREATE TABLE IF NOT EXISTS farmers (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_id UUID UNIQUE REFERENCES users(id) ON DELETE CASCADE, bio TEXT, rating FLOAT DEFAULT 0.0, total_reviews INT DEFAULT 0, certifications TEXT[] DEFAULT '{}', joined_date TIMESTAMPTZ DEFAULT NOW());
CREATE TABLE IF NOT EXISTS products (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), name VARCHAR NOT NULL, description TEXT, price FLOAT NOT NULL, unit VARCHAR NOT NULL, category VARCHAR NOT NULL, location VARCHAR NOT NULL, quantity FLOAT NOT NULL, is_organic BOOLEAN DEFAULT FALSE, created_at TIMESTAMPTZ DEFAULT NOW());
CREATE TABLE IF NOT EXISTS orders (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), buyer_id UUID REFERENCES users(id) ON DELETE CASCADE, farmer_id UUID REFERENCES farmers(id) ON DELETE CASCADE, total_amount FLOAT NOT NULL, status VARCHAR DEFAULT 'pending', created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW());
CREATE TABLE IF NOT EXISTS order_items (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), order_id UUID REFERENCES orders(id) ON DELETE CASCADE, product_id UUID REFERENCES products(id), quantity FLOAT NOT NULL, price FLOAT NOT NULL, created_at TIMESTAMPTZ DEFAULT NOW());
CREATE TABLE IF NOT EXISTS messages (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), sender_id UUID REFERENCES users(id) ON DELETE CASCADE, receiver_id UUID REFERENCES users(id) ON DELETE CASCADE, content TEXT NOT NULL, is_read BOOLEAN DEFAULT FALSE, created_at TIMESTAMPTZ DEFAULT NOW());
CREATE TABLE IF NOT EXISTS notifications (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_id UUID REFERENCES users(id) ON DELETE CASCADE, title VARCHAR NOT NULL, body TEXT, read BOOLEAN DEFAULT FALSE, data JSONB DEFAULT '{}', created_at TIMESTAMPTZ DEFAULT NOW());
CREATE TABLE IF NOT EXISTS reviews (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), order_id UUID REFERENCES orders(id) ON DELETE CASCADE, buyer_id UUID REFERENCES users(id) ON DELETE CASCADE, farmer_id UUID REFERENCES farmers(id) ON DELETE CASCADE, rating FLOAT NOT NULL CHECK (rating >= 0 AND rating <= 5), comment TEXT, created_at TIMESTAMPTZ DEFAULT NOW(), UNIQUE(order_id, buyer_id));
CREATE TABLE IF NOT EXISTS withdrawals (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), farmer_id UUID REFERENCES farmers(id) ON DELETE CASCADE, amount FLOAT NOT NULL, fee FLOAT DEFAULT 0, net_amount FLOAT NOT NULL, method VARCHAR NOT NULL, account_number VARCHAR, status VARCHAR DEFAULT 'pending', created_at TIMESTAMPTZ DEFAULT NOW());
CREATE TABLE IF NOT EXISTS device_tokens (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_id UUID REFERENCES users(id) ON DELETE CASCADE, token TEXT UNIQUE NOT NULL, platform VARCHAR, created_at TIMESTAMPTZ DEFAULT NOW());

-- ── MISSING COLUMNS ─────────────────────────────────────────────
ALTER TABLE users ADD COLUMN IF NOT EXISTS region VARCHAR;
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_image VARCHAR;
ALTER TABLE users ADD COLUMN IF NOT EXISTS language VARCHAR DEFAULT 'en';
ALTER TABLE farmers ADD COLUMN IF NOT EXISTS farm_name VARCHAR;
ALTER TABLE farmers ADD COLUMN IF NOT EXISTS region VARCHAR;
ALTER TABLE farmers ADD COLUMN IF NOT EXISTS town VARCHAR;
ALTER TABLE farmers ADD COLUMN IF NOT EXISTS farm_size FLOAT;
ALTER TABLE farmers ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE farmers ADD COLUMN IF NOT EXISTS payment_method VARCHAR;
ALTER TABLE farmers ADD COLUMN IF NOT EXISTS payment_number VARCHAR;
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
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS product_name VARCHAR;
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS unit VARCHAR;

-- ── RLS ─────────────────────────────────────────────────────────
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

-- ── POLICIES ────────────────────────────────────────────────────
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Anyone can view products') THEN CREATE POLICY "Anyone can view products" ON products FOR SELECT TO anon, authenticated USING (true); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Anyone can view farmers') THEN CREATE POLICY "Anyone can view farmers" ON farmers FOR SELECT TO anon, authenticated USING (true); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Anyone can view users') THEN CREATE POLICY "Anyone can view users" ON users FOR SELECT TO anon, authenticated USING (true); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Anyone can view reviews') THEN CREATE POLICY "Anyone can view reviews" ON reviews FOR SELECT TO anon, authenticated USING (true); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Users can update own profile') THEN CREATE POLICY "Users can update own profile" ON users FOR UPDATE TO authenticated USING (auth.uid() = id); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Users can insert own profile') THEN CREATE POLICY "Users can insert own profile" ON users FOR INSERT TO authenticated WITH CHECK (auth.uid() = id); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Users can insert products') THEN CREATE POLICY "Users can insert products" ON products FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Users can update own products') THEN CREATE POLICY "Users can update own products" ON products FOR UPDATE TO authenticated USING (auth.uid() = user_id); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Users can delete own products') THEN CREATE POLICY "Users can delete own products" ON products FOR DELETE TO authenticated USING (auth.uid() = user_id); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Users can insert farmer profile') THEN CREATE POLICY "Users can insert farmer profile" ON farmers FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Users can update own farmer profile') THEN CREATE POLICY "Users can update own farmer profile" ON farmers FOR UPDATE TO authenticated USING (auth.uid() = user_id); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Users can view own orders') THEN CREATE POLICY "Users can view own orders" ON orders FOR SELECT TO authenticated USING (auth.uid() = buyer_id OR farmer_id IN (SELECT id FROM farmers WHERE user_id = auth.uid())); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Users can insert orders') THEN CREATE POLICY "Users can insert orders" ON orders FOR INSERT TO authenticated WITH CHECK (auth.uid() = buyer_id); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Farmers can update order status') THEN CREATE POLICY "Farmers can update order status" ON orders FOR UPDATE TO authenticated USING (farmer_id IN (SELECT id FROM farmers WHERE user_id = auth.uid())); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Users can view own order items') THEN CREATE POLICY "Users can view own order items" ON order_items FOR SELECT TO authenticated USING (order_id IN (SELECT id FROM orders WHERE buyer_id = auth.uid() OR farmer_id IN (SELECT id FROM farmers WHERE user_id = auth.uid()))); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Users can insert order items') THEN CREATE POLICY "Users can insert order items" ON order_items FOR INSERT TO authenticated WITH CHECK (true); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Users can view own messages') THEN CREATE POLICY "Users can view own messages" ON messages FOR SELECT TO authenticated USING (auth.uid() = sender_id OR auth.uid() = receiver_id); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Users can send messages') THEN CREATE POLICY "Users can send messages" ON messages FOR INSERT TO authenticated WITH CHECK (auth.uid() = sender_id); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Users can mark messages as read') THEN CREATE POLICY "Users can mark messages as read" ON messages FOR UPDATE TO authenticated USING (auth.uid() = receiver_id); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Users can view own notifications') THEN CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT TO authenticated USING (auth.uid() = user_id); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Users can update own notifications') THEN CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE TO authenticated USING (auth.uid() = user_id); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='System can insert notifications') THEN CREATE POLICY "System can insert notifications" ON notifications FOR INSERT TO authenticated WITH CHECK (true); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Users can insert reviews') THEN CREATE POLICY "Users can insert reviews" ON reviews FOR INSERT TO authenticated WITH CHECK (auth.uid() = buyer_id); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Farmers can view own withdrawals') THEN CREATE POLICY "Farmers can view own withdrawals" ON withdrawals FOR SELECT TO authenticated USING (farmer_id IN (SELECT id FROM farmers WHERE user_id = auth.uid())); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Farmers can request withdrawals') THEN CREATE POLICY "Farmers can request withdrawals" ON withdrawals FOR INSERT TO authenticated WITH CHECK (farmer_id IN (SELECT id FROM farmers WHERE user_id = auth.uid())); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Users can manage own device tokens') THEN CREATE POLICY "Users can manage own device tokens" ON device_tokens FOR ALL TO authenticated USING (auth.uid() = user_id); END IF; END $$;

-- ── GRANTS ──────────────────────────────────────────────────────
GRANT SELECT ON products TO anon;
GRANT SELECT ON farmers TO anon;
GRANT SELECT ON users TO anon;
GRANT SELECT ON reviews TO anon;

-- ── REALTIME ────────────────────────────────────────────────────
DO $$ BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE products; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE orders; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE messages; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE notifications; EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ── STORAGE BUCKETS ─────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public) VALUES ('product-images', 'product-images', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('profile-images', 'profile-images', true) ON CONFLICT (id) DO NOTHING;

DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Public read images' AND tablename='objects') THEN CREATE POLICY "Public read images" ON storage.objects FOR SELECT TO anon, authenticated USING (bucket_id IN ('product-images', 'profile-images')); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Auth upload images' AND tablename='objects') THEN CREATE POLICY "Auth upload images" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id IN ('product-images', 'profile-images')); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Auth update images' AND tablename='objects') THEN CREATE POLICY "Auth update images" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id IN ('product-images', 'profile-images')); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname='Auth delete images' AND tablename='objects') THEN CREATE POLICY "Auth delete images" ON storage.objects FOR DELETE TO authenticated USING (bucket_id IN ('product-images', 'profile-images')); END IF; END $$;

-- ── VERIFY (shows table status) ─────────────────────────────────
SELECT tablename, 
       (SELECT count(*) FROM pg_policies p WHERE p.tablename = t.tablename) as policy_count
FROM pg_tables t 
WHERE schemaname = 'public' 
AND tablename IN ('users','farmers','products','orders','order_items','messages','notifications','reviews','withdrawals','device_tokens')
ORDER BY tablename;
