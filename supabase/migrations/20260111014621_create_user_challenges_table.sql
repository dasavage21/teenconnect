/*
  # Create user_challenges table

  1. New Tables
    - `user_challenges`
      - `id` (uuid, primary key) - Unique identifier for each user challenge
      - `challenge_id` (uuid, foreign key) - References the challenge being accepted
      - `accepted_at` (timestamptz) - When the challenge was accepted
      - `completed_at` (timestamptz, nullable) - When the challenge was completed
      - `status` (text) - Current status: 'accepted', 'in_progress', 'completed'

  2. Security
    - Enable RLS on `user_challenges` table
    - Add policy allowing anyone to insert (accept challenges)
    - Add policy allowing anyone to read challenges
    - Add policy allowing anyone to update their accepted challenges

  3. Notes
    - Since there's no authentication system yet, RLS policies are permissive
    - Foreign key constraint ensures challenge_id references valid challenges
*/

CREATE TABLE IF NOT EXISTS user_challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id uuid NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  accepted_at timestamptz DEFAULT now(),
  completed_at timestamptz,
  status text DEFAULT 'accepted',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE user_challenges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can accept challenges"
  ON user_challenges
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Anyone can view accepted challenges"
  ON user_challenges
  FOR SELECT
  USING (true);

CREATE POLICY "Anyone can update challenge status"
  ON user_challenges
  FOR UPDATE
  USING (true)
  WITH CHECK (true);

CREATE INDEX IF NOT EXISTS idx_user_challenges_challenge_id ON user_challenges(challenge_id);
CREATE INDEX IF NOT EXISTS idx_user_challenges_status ON user_challenges(status);
