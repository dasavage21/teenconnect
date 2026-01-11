/*
  # Clean up and fix user_challenges for Supabase Auth

  1. Changes
    - Delete orphaned user_challenges that reference non-existent users
    - Drop old foreign key constraint that references profiles table
    - Add new foreign key constraint to reference auth.users
    - Update RLS policies to use auth.uid() for proper authentication

  2. Security
    - Authenticated users can insert challenges for themselves
    - Users can only view their own challenges
    - Users can only update their own challenges
*/

-- Delete user_challenges with null user_id
DELETE FROM user_challenges WHERE user_id IS NULL;

-- Delete user_challenges where user_id doesn't exist in auth.users
DELETE FROM user_challenges 
WHERE user_id IS NOT NULL 
AND user_id NOT IN (SELECT id FROM auth.users);

-- Drop old foreign key constraint if it exists
DO $$
BEGIN
  ALTER TABLE user_challenges DROP CONSTRAINT IF EXISTS user_challenges_user_id_fkey;
EXCEPTION
  WHEN undefined_object THEN NULL;
END $$;

-- Add new foreign key to auth.users
ALTER TABLE user_challenges 
DROP CONSTRAINT IF EXISTS user_challenges_user_id_auth_fkey;

ALTER TABLE user_challenges 
ADD CONSTRAINT user_challenges_user_id_auth_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Drop old policies
DROP POLICY IF EXISTS "Anyone can accept challenges" ON user_challenges;
DROP POLICY IF EXISTS "Anyone can view accepted challenges" ON user_challenges;
DROP POLICY IF EXISTS "Users can update their own challenges" ON user_challenges;

-- Create new auth-based policies
CREATE POLICY "Authenticated users can insert their own challenges"
  ON user_challenges
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own challenges"
  ON user_challenges
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own challenges"
  ON user_challenges
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);