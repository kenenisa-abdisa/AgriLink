-- Recreate the device_tokens table completely to avoid conflicts with old structures
-- Copy and run this in your Supabase SQL Editor!

DROP TABLE IF EXISTS public.device_tokens CASCADE;

CREATE TABLE public.device_tokens (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  platform TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (user_id, token)
);

-- Enable RLS for device_tokens
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

-- Allow users to manage their own device tokens
CREATE POLICY "Users can manage their own device tokens" 
ON public.device_tokens FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Allow authenticated users to select tokens to send push notifications
CREATE POLICY "Users can read device tokens to send notifications" 
ON public.device_tokens FOR SELECT
USING (auth.role() = 'authenticated');
