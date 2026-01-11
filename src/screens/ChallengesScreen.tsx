import { useNavigate } from 'react-router-dom';
import './ChallengesScreen.css';

const ChallengesScreen = () => {
  const navigate = useNavigate();

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
        <div className="challenges-placeholder">
          <p>Challenge listings coming soon!</p>
        </div>
      </div>
    </div>
  );
};

export default ChallengesScreen;
