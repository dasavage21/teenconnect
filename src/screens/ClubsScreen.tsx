import { useNavigate } from 'react-router-dom';
import './ClubsScreen.css';

const ClubsScreen = () => {
  const navigate = useNavigate();

  return (
    <div className="clubs-container">
      <div className="clubs-content">
        <button className="back-button" onClick={() => navigate('/')}>
          ← Back to Home
        </button>
        <h1 className="clubs-title">Clubs</h1>
        <p className="clubs-description">
          Discover and join clubs that match your interests
        </p>
        <div className="clubs-placeholder">
          <p>Club listings coming soon!</p>
        </div>
      </div>
    </div>
  );
};

export default ClubsScreen;
