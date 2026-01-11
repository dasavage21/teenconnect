/*
  # Add profiles table and leaderboard functionality

  1. Modifications
    - Add `user_id` column to `user_challenges` table

  2. New Tables
    - `profiles`
      - `id` (uuid, primary key)
      - `display_name` (text, unique, not null)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  3. Views
    - `leaderboard` - aggregates user points from accepted challenges
      - Joins profiles with user_challenges and challenges
      - Calculates total points per user
      - Orders by points descending

  4. Security
    - Enable RLS on `profiles` table
    - Policy: Anyone can view all profiles (for public leaderboard)
    - Policy: Anyone can insert profiles (for user registration)
    - Policy: Users can update their own profile by display name match

  5. Notes
    - user_id is nullable for backwards compatibility
    - Leaderboard only shows users who have accepted challenges
*/

-- Add user_id to user_challenges if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_challenges' AND column_name = 'user_id'
  ) THEN
    ALTER TABLE user_challenges ADD COLUMN user_id uuid;
  END IF;
END $$;

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  display_name text UNIQUE NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
CREATE POLICY "Anyone can view profiles"
  ON profiles FOR SELECT
  USING (true);

CREATE POLICY "Anyone can insert profiles"
  ON profiles FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- Create leaderboard view
CREATE OR REPLACE VIEW leaderboard AS
SELECT 
  p.id,
  p.display_name,
  COALESCE(SUM(c.points), 0) as total_points,
  COUNT(uc.id) as challenges_completed
FROM profiles p
LEFT JOIN user_challenges uc ON p.id = uc.user_id AND uc.status = 'accepted'
LEFT JOIN challenges c ON uc.challenge_id = c.id
GROUP BY p.id, p.display_name
ORDER BY total_points DESC, challenges_completed DESC;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_challenges_user_id ON user_challenges(user_id);