import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

const ChallengesScreen = () => {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Challenges</Text>
      {/* Later you can add a list of challenges here */}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  title: {
    fontSize: 24,
  },
});

export default ChallengesScreen;
