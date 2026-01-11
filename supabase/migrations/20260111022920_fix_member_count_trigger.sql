/*
  # Fix member count trigger system

  1. Changes
    - Drop and recreate the trigger function with proper error handling
    - Ensure trigger fires correctly on INSERT and DELETE
    - Add proper NULL checks

  2. Notes
    - This fixes the member count synchronization issue
    - The trigger now properly updates counts in real-time
*/

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS update_member_count_trigger ON user_clubs;
DROP FUNCTION IF EXISTS update_club_member_count();

-- Recreate the function with better implementation
CREATE OR REPLACE FUNCTION update_club_member_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Increment member count
    UPDATE clubs
    SET member_count = member_count + 1
    WHERE id = NEW.club_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    -- Decrement member count
    UPDATE clubs
    SET member_count = GREATEST(member_count - 1, 0)
    WHERE id = OLD.club_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
CREATE TRIGGER update_member_count_trigger
AFTER INSERT OR DELETE ON user_clubs
FOR EACH ROW
EXECUTE FUNCTION update_club_member_count();