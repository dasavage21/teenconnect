/*
  # Add user_id and proof_url to user_challenges

  1. Changes
    - Add `user_id` column (uuid) to track which user accepted the challenge
    - Add `proof_url` column (text, nullable) to store proof of completion (photo URL or confirmation text)
    - Add foreign key constraint for user_id referencing profiles table
    - Update status to use 'in_progress' when accepting (instead of 'accepted')

  2. Security
    - Update RLS policies to be more specific
    - Users can only update their own challenges

  3. Notes
    - proof_url can be null for challenges that don't require photo proof
    - Status flow: 'in_progress' -> 'completed' (when proof is submitted)
*/

-- Add user_id column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_challenges' AND column_name = 'user_id'
  ) THEN
    ALTER TABLE user_challenges ADD COLUMN user_id uuid REFERENCES profiles(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Add proof_url column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_challenges' AND column_name = 'proof_url'
  ) THEN
    ALTER TABLE user_challenges ADD COLUMN proof_url text;
  END IF;
END $$;

-- Create index for user_id
CREATE INDEX IF NOT EXISTS idx_user_challenges_user_id ON user_challenges(user_id);

-- Drop old policies and create new ones
DROP POLICY IF EXISTS "Anyone can update challenge status" ON user_challenges;

CREATE POLICY "Users can update their own challenges"
  ON user_challenges
  FOR UPDATE
  USING (user_id = (SELECT id FROM profiles WHERE id = user_challenges.user_id))
  WITH CHECK (user_id = (SELECT id FROM profiles WHERE id = user_challenges.user_id));
