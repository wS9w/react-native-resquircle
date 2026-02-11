import { ScrollView, StyleSheet, Text, View } from 'react-native';
import {
  buildBoxShadow,
  ResquircleButton,
  ResquircleView,
} from 'react-native-resquircle';

export default function App() {
  const boxShadow = buildBoxShadow([
    { x: 0, y: 2, blur: 4, spread: 10, color: '#ff0000ff', opacity: 12 },
    { x: 0, y: 7, blur: 7, spread: 10, color: '#ff0000ff', opacity: 10 },
    { x: 0, y: 16, blur: 10, spread: 10, color: '#ff0000ff', opacity: 6 },
    { x: 0, y: 29, blur: 12, spread: 10, color: '#ff0000ff', opacity: 2 },
    { x: 0, y: 46, blur: 13, spread: 10, color: '#f70000ff', opacity: 0 },
  ]);

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.sectionTitle}>Basic</Text>
      <ResquircleView cornerSmoothing={1} style={[styles.card, { boxShadow }]}>
        <Text style={styles.title}>ResquircleView</Text>
        <Text style={styles.subtitle}>Native iOS + Android</Text>
      </ResquircleView>

      <Text style={styles.sectionTitle}>Button</Text>
      <ResquircleButton
        cornerSmoothing={1}
        style={styles.button}
        onPress={() => {
          console.log('pressed');
        }}
      >
        <Text style={styles.buttonText}>ResquircleButton</Text>
      </ResquircleButton>

      <Text style={styles.sectionTitle}>Smoothing</Text>
      <View style={styles.row}>
        <ResquircleView
          cornerSmoothing={0}
          style={[styles.smoothingBox, { backgroundColor: '#4CAF50' }]}
        >
          <Text style={styles.smoothingText}>0</Text>
        </ResquircleView>
        <ResquircleView
          cornerSmoothing={0.1}
          style={[styles.smoothingBox, { backgroundColor: '#2196F3' }]}
        >
          <Text style={styles.smoothingText}>0.1</Text>
        </ResquircleView>
        <ResquircleView
          cornerSmoothing={0.5}
          style={[styles.smoothingBox, { backgroundColor: '#FF9800' }]}
        >
          <Text style={styles.smoothingText}>0.5</Text>
        </ResquircleView>
        <ResquircleView
          cornerSmoothing={1}
          style={[styles.smoothingBox, { backgroundColor: '#F44336' }]}
        >
          <Text style={styles.smoothingText}>1</Text>
        </ResquircleView>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F1F5F9',
  },
  content: {
    padding: 16,
    gap: 16,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#1E293B',
    marginTop: 8,
    marginBottom: 8,
  },
  card: {
    height: 120,
    borderRadius: 24,
    borderWidth: 2,
    borderColor: 'red',
    backgroundColor: 'white',
    justifyContent: 'center',
    paddingHorizontal: 16,
  },
  title: {
    fontSize: 18,
    fontWeight: '700',
    color: '#111',
  },
  subtitle: {
    marginTop: 2,
    fontSize: 13,
    color: '#111',
    opacity: 0.8,
  },
  button: {
    height: 60,
    borderRadius: 20,
    borderWidth: 2,
    borderColor: '#3B82F6',
    backgroundColor: '#3B82F6',
    alignItems: 'center',
    justifyContent: 'center',
  },
  buttonText: {
    fontSize: 16,
    fontWeight: '700',
    color: 'white',
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 20,
  },
  smoothingBox: {
    width: 80,
    height: 80,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  smoothingText: {
    fontSize: 14,
    fontWeight: '700',
    color: 'white',
  },
});
