-- Fix the Foreign Key constraint between public.users and auth.users
-- This allows the "Delete Account" CASCADE trigger to successfully delete the user's public profile and cascade to all other tables!

-- 1. Drop the existing foreign key constraint on the public.users table if it exists
ALTER TABLE public.users 
DROP CONSTRAINT IF EXISTS users_id_fkey;

-- 2. Re-add the foreign key constraint with ON DELETE CASCADE
ALTER TABLE public.users 
ADD CONSTRAINT users_id_fkey 
FOREIGN KEY (id) 
REFERENCES auth.users(id) 
ON DELETE CASCADE;
