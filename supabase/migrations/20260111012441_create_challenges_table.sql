/*
  # Create challenges table

  1. New Tables
    - `challenges`
      - `id` (uuid, primary key) - Unique identifier for each challenge
      - `title` (text) - Challenge title
      - `description` (text) - Detailed description of the challenge
      - `difficulty` (text) - Challenge difficulty level (easy, medium, hard)
      - `points` (integer) - Points awarded for completing the challenge
      - `category` (text) - Challenge category (fitness, creative, social, learning)
      - `created_at` (timestamptz) - Timestamp when challenge was created
      
  2. Security
    - Enable RLS on `challenges` table
    - Add policy for public read access (anyone can view challenges)
    - Future: Can add policies for authenticated users to create challenges
*/

CREATE TABLE IF NOT EXISTS challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text NOT NULL,
  difficulty text NOT NULL DEFAULT 'medium',
  points integer NOT NULL DEFAULT 10,
  category text NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view challenges"
  ON challenges
  FOR SELECT
  TO anon, authenticated
  USING (true);
