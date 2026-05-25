-- Recreate device_tokens table with explicit system grants to prevent "Permission Denied" errors!
-- Copy and run this in your Supabase SQL Editor!

-- 1. Drop the table first
DROP TABLE IF EXISTS public.device_tokens CASCADE;

-- 2. Create the table with correct types
CREATE TABLE public.device_tokens (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  platform TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (user_id, token)
);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

-- 4. CRITICAL: Grant full table privileges to Supabase client roles!
-- Without these, the Supabase API returns "permission denied" (42501)
GRANT ALL ON public.device_tokens TO authenticated;
GRANT ALL ON public.device_tokens TO anon;
GRANT ALL ON public.device_tokens TO service_role;

-- 5. Create secure RLS policies
-- Allow users to manage (insert, update, delete) their own active device tokens
CREATE POLICY "Users can manage their own device tokens" 
ON public.device_tokens FOR ALL
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Allow authenticated users to view tokens to look up who to send background pushes to
CREATE POLICY "Allow authenticated users to read tokens to send notifications" 
ON public.device_tokens FOR SELECT
TO authenticated
USING (true);
