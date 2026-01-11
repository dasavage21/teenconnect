import { useNavigate } from 'react-router-dom';
import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';
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

interface UserChallenge {
  id: string;
  challenge_id: string;
  status: 'in_progress' | 'completed';
  proof_url: string | null;
  completed_at: string | null;
}

interface LeaderboardEntry {
  id: string;
  display_name: string;
  total_points: number;
  challenges_completed: number;
}

const ChallengesScreen = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [challenges, setChallenges] = useState<Challenge[]>([]);
  const [userChallenges, setUserChallenges] = useState<Map<string, UserChallenge>>(new Map());
  const [loading, setLoading] = useState(true);
  const [acceptingId, setAcceptingId] = useState<string | null>(null);
  const [userProfile, setUserProfile] = useState<LeaderboardEntry | null>(null);
  const [leaderboard, setLeaderboard] = useState<LeaderboardEntry[]>([]);
  const [showCompletionModal, setShowCompletionModal] = useState(false);
  const [selectedChallenge, setSelectedChallenge] = useState<Challenge | null>(null);
  const [proofUrl, setProofUrl] = useState('');
  const [submittingProof, setSubmittingProof] = useState(false);

  useEffect(() => {
    if (user) {
      loadUserProfile();
      fetchChallenges();
      fetchAcceptedChallenges();
      fetchLeaderboard();
    }
  }, [user]);

  const loadUserProfile = async () => {
    if (!user) return;

    try {
      const { data, error } = await supabase
        .from('leaderboard')
        .select('*')
        .eq('id', user.id)
        .maybeSingle();

      if (error) throw error;
      setUserProfile(data);
    } catch (error) {
      console.error('Error loading user profile:', error);
    }
  };

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

  const fetchAcceptedChallenges = async () => {
    if (!user) {
      setUserChallenges(new Map());
      return;
    }

    try {
      const { data, error } = await supabase
        .from('user_challenges')
        .select('id, challenge_id, status, proof_url, completed_at')
        .eq('user_id', user.id);

      if (error) throw error;

      const challengesMap = new Map<string, UserChallenge>();
      data?.forEach(uc => {
        challengesMap.set(uc.challenge_id, uc as UserChallenge);
      });
      setUserChallenges(challengesMap);
    } catch (error) {
      console.error('Error fetching user challenges:', error);
    }
  };

  const fetchLeaderboard = async () => {
    try {
      const { data, error } = await supabase
        .from('leaderboard')
        .select('*')
        .limit(10);

      if (error) throw error;
      setLeaderboard(data || []);
    } catch (error) {
      console.error('Error fetching leaderboard:', error);
    }
  };

  const handleAcceptChallenge = async (challengeId: string) => {
    if (!user) return;

    setAcceptingId(challengeId);
    try {
      const { data, error } = await supabase
        .from('user_challenges')
        .insert({
          challenge_id: challengeId,
          status: 'in_progress',
          user_id: user.id
        })
        .select()
        .single();

      if (error) throw error;

      setUserChallenges(prev => {
        const newMap = new Map(prev);
        newMap.set(challengeId, data as UserChallenge);
        return newMap;
      });
    } catch (error) {
      console.error('Error accepting challenge:', error);
      alert('Failed to accept challenge. Please try again.');
    } finally {
      setAcceptingId(null);
    }
  };

  const handleCompleteChallenge = (challenge: Challenge) => {
    setSelectedChallenge(challenge);
    setShowCompletionModal(true);
    setProofUrl('');
  };

  const handleSubmitProof = async () => {
    if (!selectedChallenge || !user) return;

    const userChallenge = userChallenges.get(selectedChallenge.id);
    if (!userChallenge) return;

    setSubmittingProof(true);
    try {
      const { data, error } = await supabase
        .from('user_challenges')
        .update({
          status: 'completed',
          proof_url: proofUrl || 'confirmed',
          completed_at: new Date().toISOString()
        })
        .eq('id', userChallenge.id)
        .select()
        .single();

      if (error) throw error;

      setUserChallenges(prev => {
        const newMap = new Map(prev);
        newMap.set(selectedChallenge.id, data as UserChallenge);
        return newMap;
      });

      setShowCompletionModal(false);
      setSelectedChallenge(null);
      setProofUrl('');
      loadUserProfile();
      fetchLeaderboard();
    } catch (error) {
      console.error('Error completing challenge:', error);
      alert('Failed to complete challenge. Please try again.');
    } finally {
      setSubmittingProof(false);
    }
  };

  const getTotalPoints = () => {
    return challenges
      .filter(challenge => {
        const userChallenge = userChallenges.get(challenge.id);
        return userChallenge && userChallenge.status === 'completed';
      })
      .reduce((sum, challenge) => sum + challenge.points, 0);
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

        <div className="header-row">
          <div className="total-points-display">
            <span className="total-points-label">
              {userProfile ? `${userProfile.display_name}'s Points:` : 'Total Points:'}
            </span>
            <span className="total-points-value">⭐ {getTotalPoints()}</span>
          </div>
        </div>

        {leaderboard.length > 0 && (
          <div className="leaderboard-section">
            <h2 className="leaderboard-title">Leaderboard</h2>
            <div className="leaderboard-list">
              {leaderboard.map((entry, index) => (
                <div
                  key={entry.id}
                  className={`leaderboard-item ${user?.id === entry.id ? 'current-user' : ''}`}
                >
                  <div className="leaderboard-rank">
                    {index === 0 ? '🥇' : index === 1 ? '🥈' : index === 2 ? '🥉' : `#${index + 1}`}
                  </div>
                  <div className="leaderboard-name">{entry.display_name}</div>
                  <div className="leaderboard-stats">
                    <span className="leaderboard-points">⭐ {entry.total_points}</span>
                    <span className="leaderboard-challenges">{entry.challenges_completed} challenges</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

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
                  {(() => {
                    const userChallenge = userChallenges.get(challenge.id);
                    if (!userChallenge) {
                      return (
                        <button
                          className="accept-button"
                          onClick={() => handleAcceptChallenge(challenge.id)}
                          disabled={acceptingId === challenge.id}
                        >
                          {acceptingId === challenge.id ? 'Accepting...' : 'Accept Challenge'}
                        </button>
                      );
                    }
                    if (userChallenge.status === 'in_progress') {
                      return (
                        <button
                          className="complete-button"
                          onClick={() => handleCompleteChallenge(challenge)}
                        >
                          Submit Proof
                        </button>
                      );
                    }
                    return (
                      <button
                        className="completed-button"
                        disabled
                        style={{ opacity: 0.7, cursor: 'default' }}
                      >
                        Completed ✓
                      </button>
                    );
                  })()}
                </div>
              </div>
            ))}
          </div>
        )}

        {showCompletionModal && selectedChallenge && (
          <div className="modal-overlay" onClick={() => setShowCompletionModal(false)}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
              <h2 className="modal-title">Complete Challenge</h2>
              <h3 className="challenge-name">{selectedChallenge.title}</h3>
              <p className="modal-description">
                Submit proof of completion to earn {selectedChallenge.points} points!
              </p>
              <div className="proof-options">
                <label className="proof-label">
                  Photo URL (optional):
                  <input
                    type="text"
                    className="profile-input"
                    placeholder="Paste image URL or leave blank to confirm"
                    value={proofUrl}
                    onChange={(e) => setProofUrl(e.target.value)}
                    disabled={submittingProof}
                  />
                </label>
                <p className="proof-hint">
                  You can upload a photo to an image hosting service and paste the URL, or simply click Complete to confirm you've finished the challenge.
                </p>
              </div>
              <div className="modal-actions">
                <button
                  className="modal-button cancel"
                  onClick={() => setShowCompletionModal(false)}
                  disabled={submittingProof}
                >
                  Cancel
                </button>
                <button
                  className="modal-button create"
                  onClick={handleSubmitProof}
                  disabled={submittingProof}
                >
                  {submittingProof ? 'Completing...' : 'Complete Challenge'}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default ChallengesScreen;
