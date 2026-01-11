import { useNavigate } from 'react-router-dom';
import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import './ChallengesScreen.css';

interface Challenge {
  id: string;
  title: string;
  description: string;
  difficulty: string;
  points: number;
  category: string;
  created_at: string;
}

const ChallengesScreen = () => {
  const navigate = useNavigate();
  const [challenges, setChallenges] = useState<Challenge[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchChallenges();
  }, []);

  const fetchChallenges = async () => {
    try {
      const { data, error } = await supabase
        .from('challenges')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setChallenges(data || []);
    } catch (error) {
      console.error('Error fetching challenges:', error);
    } finally {
      setLoading(false);
    }
  };

  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return '#10b981';
      case 'medium':
        return '#f59e0b';
      case 'hard':
        return '#ef4444';
      default:
        return '#6b7280';
    }
  };

  const getCategoryIcon = (category: string) => {
    switch (category.toLowerCase()) {
      case 'fitness':
        return '💪';
      case 'creative':
        return '🎨';
      case 'social':
        return '🤝';
      case 'learning':
        return '📚';
      default:
        return '🎯';
    }
  };

  return (
    <div className="challenges-container">
      <div className="challenges-content">
        <button className="back-button" onClick={() => navigate('/')}>
          ← Back to Home
        </button>
        <h1 className="challenges-title">Challenges</h1>
        <p className="challenges-description">
          Take on exciting challenges and compete with friends
        </p>

        {loading ? (
          <div className="loading">Loading challenges...</div>
        ) : challenges.length === 0 ? (
          <div className="challenges-placeholder">
            <p>No challenges available yet!</p>
          </div>
        ) : (
          <div className="challenges-grid">
            {challenges.map((challenge) => (
              <div key={challenge.id} className="challenge-card">
                <div className="challenge-header">
                  <span className="challenge-category">
                    {getCategoryIcon(challenge.category)} {challenge.category}
                  </span>
                  <span
                    className="challenge-difficulty"
                    style={{ backgroundColor: getDifficultyColor(challenge.difficulty) }}
                  >
                    {challenge.difficulty}
                  </span>
                </div>
                <h3 className="challenge-title-text">{challenge.title}</h3>
                <p className="challenge-description-text">{challenge.description}</p>
                <div className="challenge-footer">
                  <span className="challenge-points">⭐ {challenge.points} points</span>
                  <button className="accept-button">Accept Challenge</button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default ChallengesScreen;
