-- Add online presence tracking fields to the public.users table.
-- Run this in your Supabase SQL Editor!

ALTER TABLE public.users ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT FALSE;

-- Grant permissions to make sure all authenticated users can update their own presence status
GRANT ALL ON public.users TO authenticated;
GRANT ALL ON public.users TO anon;
GRANT ALL ON public.users TO service_role;

-- Secure SECURITY DEFINER function to handle device token registrations without RLS/upsert conflict failures
CREATE OR REPLACE FUNCTION public.register_device_token(fcm_token TEXT, client_platform TEXT)
RETURNS VOID AS $$
BEGIN
  -- Delete any existing registration for this specific token to avoid conflicts (e.g. from previous users of this device)
  DELETE FROM public.device_tokens WHERE token = fcm_token;
  
  -- Insert the new token for the currently authenticated user
  INSERT INTO public.device_tokens (user_id, token, platform, updated_at)
  VALUES (auth.uid(), fcm_token, client_platform, NOW());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execution permissions
GRANT EXECUTE ON FUNCTION public.register_device_token(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.register_device_token(TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.register_device_token(TEXT, TEXT) TO service_role;
