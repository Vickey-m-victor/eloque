import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/practice_result.dart';
import '../services/database_helper.dart';

class ProgressProvider with ChangeNotifier {
  final List<PracticeResult> _results = [];
  int _streakDays = 3; // Default starting streak value
  bool _isLoading = false;
  String _userName = 'English Learner';

  ProgressProvider() {
    _loadResults();
    _loadPreferences();
  }

  String get userName => _userName;

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userName = prefs.getString('user_name') ?? 'English Learner';
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user preferences in provider: $e');
    }
  }

  Future<void> updateUserName(String newName) async {
    _userName = newName;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', newName);
    } catch (e) {
      debugPrint('Error saving user name in provider: $e');
    }
  }

  List<PracticeResult> get results => List.unmodifiable(_results);

  int get streakDays => _streakDays;

  bool get isLoading => _isLoading;

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

  Future<void> _loadResults() async {
    _isLoading = true;
    notifyListeners();
    try {
      final dbResults = await DatabaseHelper.instance.fetchAllResults();
      _results.clear();
      if (dbResults.isEmpty) {
        // Seed with initial mock results on very first run
        _loadMockData();
        for (final res in _results) {
          await DatabaseHelper.instance.insertResult(res);
        }
      } else {
        _results.addAll(dbResults);
      }
    } catch (e) {
      debugPrint('Error loading results from database: $e');
      _loadMockData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveResult(PracticeResult result) async {
    _results.insert(0, result); // insert at the top of the history list
    _streakDays++; 
    notifyListeners();

    try {
      await DatabaseHelper.instance.insertResult(result);
    } catch (e) {
      debugPrint('Error saving result to DB: $e');
    }
  }

  Future<void> clearHistory() async {
    _results.clear();
    _streakDays = 0;
    notifyListeners();
    try {
      await DatabaseHelper.instance.clearAllResults();
    } catch (e) {
      debugPrint('Error clearing DB results: $e');
    }
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
