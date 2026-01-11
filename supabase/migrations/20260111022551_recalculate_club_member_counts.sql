/*
  # Recalculate and sync club member counts

  1. Updates
    - Recalculate member_count for all clubs based on actual user_clubs records
    - Ensures member_count column is in sync with reality

  2. Notes
    - This fixes any discrepancies between stored counts and actual memberships
    - The trigger will keep counts accurate going forward
*/

-- Recalculate member counts for all clubs
UPDATE clubs c
SET member_count = (
  SELECT COUNT(*)
  FROM user_clubs uc
  WHERE uc.club_id = c.id
);