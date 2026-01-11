import { useNavigate } from 'react-router-dom';
import './HomeScreen.css';

const HomeScreen = () => {
  const navigate = useNavigate();

  return (
    <div className="home-container">
      <div className="home-content">
        <h1 className="home-title">Welcome to TeenConnect!</h1>
        <p className="home-subtitle">Connect with friends, join clubs, and take on challenges</p>
        <div className="button-group">
          <button className="nav-button" onClick={() => navigate('/clubs')}>
            Go to Clubs
          </button>
          <button className="nav-button" onClick={() => navigate('/challenges')}>
            Go to Challenges
          </button>
        </div>
      </div>
    </div>
  );
};

export default HomeScreen;
