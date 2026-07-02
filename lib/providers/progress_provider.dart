import 'package:flutter/material.dart';
import '../models/practice_result.dart';

class ProgressProvider with ChangeNotifier {
  final List<PracticeResult> _results = [];
  int _streakDays = 3; // Start with mock streak

  ProgressProvider() {
    _loadMockData();
  }

  List<PracticeResult> get results => List.unmodifiable(_results);

  int get streakDays => _streakDays;

  int get completedLessonsCount => _results.map((r) => r.lessonId).toSet().length;

  int get totalPracticeMinutes {
    final totalSeconds = _results.fold<int>(0, (sum, r) => sum + r.sessionDuration.inSeconds);
    return (totalSeconds / 60).ceil();
  }

  int get averageFluencyScore {
    if (_results.isEmpty) return 0;
    final totalFluency = _results.fold<double>(0.0, (sum, r) => sum + r.fluencyScore);
    return (totalFluency / _results.length).round();
  }

  void saveResult(PracticeResult result) {
    _results.add(result);
    
    // Update streak logic (basic demonstration helper)
    // If today is a new day practicing, increment or maintain streak.
    _streakDays++; 
    notifyListeners();
  }

  void _loadMockData() {
    // Populate with 2 initial mock results to mirror the original MVP statistics
    _results.addAll([
      PracticeResult(
        id: 'mock_1',
        lessonId: '1',
        audioFilePath: '',
        transcript: 'Hi everyone, my name is Alex. Have you ever wondered why we spend hours managing emails...',
        completedAt: DateTime.now().subtract(const Duration(days: 2)),
        sessionDuration: const Duration(minutes: 6),
        targetWpm: 140,
        actualWpm: 135,
        accuracyScore: 88.0,
        fillerWordCount: 1,
        fluencyScore: 84.0,
      ),
      PracticeResult(
        id: 'mock_2',
        lessonId: '4',
        audioFilePath: '',
        transcript: 'Hi there! I would like to get a medium iced caramel macchiato, please...',
        completedAt: DateTime.now().subtract(const Duration(days: 1)),
        sessionDuration: const Duration(minutes: 8),
        targetWpm: 140,
        actualWpm: 142,
        accuracyScore: 92.0,
        fillerWordCount: 0,
        fluencyScore: 94.0,
      ),
    ]);
  }
}
