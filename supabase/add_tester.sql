-- Add user to tester cohort for AI chat access
-- Run this in Supabase Dashboard > SQL Editor

-- First, insert the profile if it doesn't exist
-- The user_id should match your auth.users id
INSERT INTO profiles (id, email, metadata)
SELECT 
  id,
  email,
  '{"tester": true}'::jsonb
FROM auth.users
WHERE email = 'damiuxcodes@gmail.com'
ON CONFLICT (id) 
DO UPDATE SET 
  metadata = jsonb_set(
    COALESCE(profiles.metadata, '{}'::jsonb), 
    '{tester}', 
    'true'::jsonb
  );

-- Verify the update
SELECT id, email, metadata 
FROM profiles 
WHERE email = 'damiuxcodes@gmail.com';
