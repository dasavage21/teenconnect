/*
  # Create profiles system linked to auth.users

  1. New Tables
    - Recreate `profiles` table linked to auth.users
      - `id` (uuid, primary key) - References auth.users(id)
      - `display_name` (text, not null) - User's display name
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Functions & Triggers
    - Function to create profile when user signs up
    - Trigger on auth.users to auto-create profile

  3. Views
    - Update `leaderboard` view to show completed challenges

  4. Security
    - Enable RLS on profiles
    - Users can view all profiles
    - Users can only update their own profile

  5. Data Migration
    - Create profiles for existing auth users with email as display name
*/

-- Drop old profiles table if it exists
DROP TABLE IF EXISTS profiles CASCADE;

-- Create new profiles table linked to auth.users
CREATE TABLE profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Anyone can view profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert their own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Function to handle new user profile creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, display_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'display_name', SPLIT_PART(NEW.email, '@', 1))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Create profiles for existing users
INSERT INTO profiles (id, display_name)
SELECT 
  id, 
  COALESCE(raw_user_meta_data->>'display_name', SPLIT_PART(email, '@', 1))
FROM auth.users
WHERE id NOT IN (SELECT id FROM profiles)
ON CONFLICT (id) DO NOTHING;

-- Recreate leaderboard view
DROP VIEW IF EXISTS leaderboard;
CREATE OR REPLACE VIEW leaderboard AS
SELECT 
  p.id,
  p.display_name,
  COALESCE(SUM(c.points), 0) as total_points,
  COUNT(CASE WHEN uc.status = 'completed' THEN 1 END) as challenges_completed
FROM profiles p
LEFT JOIN user_challenges uc ON p.id = uc.user_id
LEFT JOIN challenges c ON uc.challenge_id = c.id AND uc.status = 'completed'
GROUP BY p.id, p.display_name
ORDER BY total_points DESC, challenges_completed DESC;