import { useNavigate } from 'react-router-dom';
import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import './ClubsScreen.css';

interface Club {
  id: string;
  name: string;
  description: string;
  category: string;
  image_url: string;
  member_count: number;
}

interface UserClub {
  club_id: string;
}

const ClubsScreen = () => {
  const navigate = useNavigate();
  const [clubs, setClubs] = useState<Club[]>([]);
  const [userClubs, setUserClubs] = useState<Set<string>>(new Set());
  const [loading, setLoading] = useState(true);
  const [userId, setUserId] = useState<string | null>(null);
  const [filter, setFilter] = useState<string>('all');

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      setUserId(user?.id || null);

      const { data: clubsData, error: clubsError } = await supabase
        .from('clubs')
        .select('*')
        .order('member_count', { ascending: false });

      if (clubsError) throw clubsError;
      setClubs(clubsData || []);

      if (user) {
        const { data: userClubsData, error: userClubsError } = await supabase
          .from('user_clubs')
          .select('club_id')
          .eq('user_id', user.id);

        if (userClubsError) throw userClubsError;
        setUserClubs(new Set(userClubsData?.map((uc: UserClub) => uc.club_id) || []));
      }
    } catch (error) {
      console.error('Error loading clubs:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleJoinLeave = async (clubId: string, isJoined: boolean) => {
    if (!userId) {
      alert('Please log in to join clubs');
      return;
    }

    try {
      if (isJoined) {
        const { error } = await supabase
          .from('user_clubs')
          .delete()
          .eq('user_id', userId)
          .eq('club_id', clubId);

        if (error) throw error;

        setUserClubs(prev => {
          const newSet = new Set(prev);
          newSet.delete(clubId);
          return newSet;
        });

        setClubs(prev => prev.map(club =>
          club.id === clubId
            ? { ...club, member_count: Math.max(0, club.member_count - 1) }
            : club
        ));
      } else {
        const { error } = await supabase
          .from('user_clubs')
          .insert({ user_id: userId, club_id: clubId });

        if (error) throw error;

        setUserClubs(prev => new Set([...prev, clubId]));

        setClubs(prev => prev.map(club =>
          club.id === clubId
            ? { ...club, member_count: club.member_count + 1 }
            : club
        ));
      }
    } catch (error) {
      console.error('Error joining/leaving club:', error);
      alert('Failed to update membership. Please try again.');
      await loadData();
    }
  };

  const categories = ['all', ...new Set(clubs.map(club => club.category))];
  const filteredClubs = filter === 'all'
    ? clubs
    : clubs.filter(club => club.category === filter);

  if (loading) {
    return (
      <div className="clubs-container">
        <div className="clubs-content">
          <p className="loading-text">Loading clubs...</p>
        </div>
      </div>
    );
  }

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

        <div className="filter-tabs">
          {categories.map(category => (
            <button
              key={category}
              className={`filter-tab ${filter === category ? 'active' : ''}`}
              onClick={() => setFilter(category)}
            >
              {category.charAt(0).toUpperCase() + category.slice(1)}
            </button>
          ))}
        </div>

        <div className="clubs-grid">
          {filteredClubs.map(club => {
            const isJoined = userClubs.has(club.id);
            return (
              <div key={club.id} className="club-card">
                <div
                  className="club-image"
                  style={{ backgroundImage: `url(${club.image_url})` }}
                >
                  <div className="club-category-badge">{club.category}</div>
                </div>
                <div className="club-info">
                  <h3 className="club-name">{club.name}</h3>
                  <p className="club-description">{club.description}</p>
                  <div className="club-footer">
                    <span className="member-count">
                      {club.member_count} {club.member_count === 1 ? 'member' : 'members'}
                    </span>
                    <button
                      className={`join-button ${isJoined ? 'joined' : ''}`}
                      onClick={() => handleJoinLeave(club.id, isJoined)}
                    >
                      {isJoined ? 'Leave' : 'Join'}
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        {filteredClubs.length === 0 && (
          <div className="no-clubs">
            <p>No clubs found in this category.</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default ClubsScreen;
