import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

const ClubsScreen = () => {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Clubs</Text>
      {/* Later you can add a list of clubs here */}
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

export default ClubsScreen;
