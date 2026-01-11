import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import HomeScreen from './screens/HomeScreen';
import ClubsScreen from './screens/ClubsScreen';
import ChallengesScreen from './screens/ChallengesScreen';

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<HomeScreen />} />
        <Route path="/clubs" element={<ClubsScreen />} />
        <Route path="/challenges" element={<ChallengesScreen />} />
      </Routes>
    </Router>
  );
}

export default App;
