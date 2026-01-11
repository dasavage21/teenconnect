/*
  # Create Clubs System

  1. New Tables
    - `clubs`
      - `id` (uuid, primary key) - Unique identifier for each club
      - `name` (text) - Name of the club
      - `description` (text) - Description of what the club is about
      - `category` (text) - Category/type of club (sports, arts, tech, etc.)
      - `image_url` (text) - URL to club image/icon
      - `member_count` (integer) - Number of members in the club
      - `created_at` (timestamptz) - When the club was created
    
    - `user_clubs`
      - `id` (uuid, primary key) - Unique identifier for membership
      - `user_id` (uuid, foreign key) - Reference to auth.users
      - `club_id` (uuid, foreign key) - Reference to clubs table
      - `joined_at` (timestamptz) - When the user joined
      - `created_at` (timestamptz) - Record creation timestamp
      - Unique constraint on (user_id, club_id) to prevent duplicate memberships

  2. Security
    - Enable RLS on both tables
    - Anyone can view clubs
    - Only authenticated users can join/leave clubs
    - Users can only manage their own memberships
    
  3. Functions
    - Trigger to automatically update member_count when users join/leave clubs
*/

-- Create clubs table
CREATE TABLE IF NOT EXISTS clubs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text NOT NULL,
  category text NOT NULL,
  image_url text DEFAULT '',
  member_count integer DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Create user_clubs table
CREATE TABLE IF NOT EXISTS user_clubs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  club_id uuid REFERENCES clubs(id) ON DELETE CASCADE,
  joined_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, club_id)
);

-- Enable RLS
ALTER TABLE clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_clubs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for clubs table
CREATE POLICY "Anyone can view clubs"
  ON clubs FOR SELECT
  TO public
  USING (true);

-- RLS Policies for user_clubs table
CREATE POLICY "Anyone can view club memberships"
  ON user_clubs FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Authenticated users can join clubs"
  ON user_clubs FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can leave their clubs"
  ON user_clubs FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Function to update member count
CREATE OR REPLACE FUNCTION update_club_member_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE clubs
    SET member_count = member_count + 1
    WHERE id = NEW.club_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE clubs
    SET member_count = member_count - 1
    WHERE id = OLD.club_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for member count updates
DROP TRIGGER IF EXISTS update_member_count_trigger ON user_clubs;
CREATE TRIGGER update_member_count_trigger
  AFTER INSERT OR DELETE ON user_clubs
  FOR EACH ROW
  EXECUTE FUNCTION update_club_member_count();

-- Insert sample clubs
INSERT INTO clubs (name, description, category, image_url) VALUES
  ('Photography Club', 'Explore the world through your lens. Share photos, learn techniques, and go on photo walks together.', 'arts', 'https://images.pexels.com/photos/606541/pexels-photo-606541.jpeg?auto=compress&cs=tinysrgb&w=400'),
  ('Coding & Tech', 'Learn to code, build apps, and discuss the latest in technology. All skill levels welcome!', 'tech', 'https://images.pexels.com/photos/1181467/pexels-photo-1181467.jpeg?auto=compress&cs=tinysrgb&w=400'),
  ('Basketball Squad', 'Weekly pickup games and basketball training sessions. Improve your skills and have fun!', 'sports', 'https://images.pexels.com/photos/1752757/pexels-photo-1752757.jpeg?auto=compress&cs=tinysrgb&w=400'),
  ('Book Club', 'Read together, discuss stories, and discover new authors. Monthly book selections and meetups.', 'learning', 'https://images.pexels.com/photos/159866/books-book-pages-read-literature-159866.jpeg?auto=compress&cs=tinysrgb&w=400'),
  ('Music Makers', 'For musicians of all kinds. Jam sessions, music theory, and collaborative projects.', 'arts', 'https://images.pexels.com/photos/1751731/pexels-photo-1751731.jpeg?auto=compress&cs=tinysrgb&w=400'),
  ('Fitness & Wellness', 'Stay active together with workout challenges, yoga sessions, and wellness tips.', 'fitness', 'https://images.pexels.com/photos/841130/pexels-photo-841130.jpeg?auto=compress&cs=tinysrgb&w=400'),
  ('Art Studio', 'Paint, draw, and create art together. Share your work and learn new techniques.', 'arts', 'https://images.pexels.com/photos/1428171/pexels-photo-1428171.jpeg?auto=compress&cs=tinysrgb&w=400'),
  ('Gaming Community', 'Connect with fellow gamers. Tournaments, game nights, and friendly competition.', 'gaming', 'https://images.pexels.com/photos/3945683/pexels-photo-3945683.jpeg?auto=compress&cs=tinysrgb&w=400'),
  ('Cooking & Baking', 'Share recipes, cooking tips, and organize potlucks. From beginners to master chefs!', 'lifestyle', 'https://images.pexels.com/photos/1435904/pexels-photo-1435904.jpeg?auto=compress&cs=tinysrgb&w=400'),
  ('Debate Society', 'Sharpen your critical thinking and public speaking skills through structured debates.', 'learning', 'https://images.pexels.com/photos/5325836/pexels-photo-5325836.jpeg?auto=compress&cs=tinysrgb&w=400')
ON CONFLICT DO NOTHING;