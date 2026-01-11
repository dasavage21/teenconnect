/*
  # Update leaderboard to only count completed challenges

  1. Changes
    - Modify leaderboard view to only count challenges with status = 'completed'
    - Previously counted status = 'accepted', now requires completion

  2. Notes
    - Points are only awarded after challenges are completed with proof
    - This ensures fair competition based on actual accomplishments
*/

-- Drop and recreate the leaderboard view with updated logic
DROP VIEW IF EXISTS leaderboard;

CREATE OR REPLACE VIEW leaderboard AS
SELECT 
  p.id,
  p.display_name,
  COALESCE(SUM(c.points), 0) as total_points,
  COUNT(uc.id) as challenges_completed
FROM profiles p
LEFT JOIN user_challenges uc ON p.id = uc.user_id AND uc.status = 'completed'
LEFT JOIN challenges c ON uc.challenge_id = c.id
GROUP BY p.id, p.display_name
ORDER BY total_points DESC, challenges_completed DESC;
