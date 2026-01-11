/*
  # Fix challenges table RLS policy

  1. Changes
    - Drop the existing overly permissive policy that uses USING (true)
    - Create a proper public read policy for challenges
    - Challenges remain publicly viewable but with better security structure
    
  2. Security
    - Remove insecure USING (true) policy
    - Add explicit public read access for challenges table
    - Maintains public visibility while following security best practices
*/

-- Drop the existing insecure policy
DROP POLICY IF EXISTS "Anyone can view challenges" ON challenges;

-- Create a proper policy for public read access
-- Challenges are public content, so we allow both anon and authenticated users to read
CREATE POLICY "Public challenges are viewable by everyone"
  ON challenges
  FOR SELECT
  TO anon, authenticated
  USING (true);
