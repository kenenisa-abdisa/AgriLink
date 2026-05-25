-- Account Deletion RPC
-- This allows a user to delete their own account securely without needing the service role key.
-- Since user_id references auth.users(id) ON DELETE CASCADE, this will delete everything associated with the user.

CREATE OR REPLACE FUNCTION delete_user_account() 
RETURNS void AS $$
BEGIN
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
