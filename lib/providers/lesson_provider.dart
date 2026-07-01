import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../utils/dummy_data.dart';

class LessonProvider with ChangeNotifier {
  final List<Lesson> _lessons = dummyLessons;
  String _selectedCategory = 'All';
  String _selectedDifficulty = 'All';
  Lesson? _selectedLesson;

  // Mock User Statistics for MVP
  int _completedLessonsCount = 2;
  int _totalPracticeMinutes = 14;
  int _averageFluencyScore = 78;
  int _streakDays = 3;
  final List<String> _completedLessonIds = ['4']; // Lesson 4 is completed initially

  // Getters for filtering
  String get selectedCategory => _selectedCategory;
  String get selectedDifficulty => _selectedDifficulty;
  Lesson? get selectedLesson => _selectedLesson;

  // Stats getters
  int get completedLessonsCount => _completedLessonsCount;
  int get totalPracticeMinutes => _totalPracticeMinutes;
  int get averageFluencyScore => _averageFluencyScore;
  int get streakDays => _streakDays;

  // Filtered lessons
  List<Lesson> get lessons {
    return _lessons.where((lesson) {
      final matchesCategory = _selectedCategory == 'All' || lesson.category == _selectedCategory;
      final matchesDifficulty = _selectedDifficulty == 'All' || lesson.difficulty == _selectedDifficulty;
      return matchesCategory && matchesDifficulty;
    }).toList();
  }

  List<Lesson> get allLessons => _lessons;

  // Get all unique categories in dummy data
  List<String> get categories {
    final Set<String> cats = {'All'};
    for (var lesson in _lessons) {
      cats.add(lesson.category);
    }
    return cats.toList();
  }

  // Get all difficulties
  List<String> get difficulties => ['All', 'Beginner', 'Intermediate', 'Advanced'];

  void selectCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  void selectDifficulty(String difficulty) {
    if (_selectedDifficulty != difficulty) {
      _selectedDifficulty = difficulty;
      notifyListeners();
    }
  }

  void selectLesson(Lesson? lesson) {
    _selectedLesson = lesson;
    notifyListeners();
  }

  // Add practice stats
  void completeLesson(String lessonId, int minutesRead, int score) {
    if (!_completedLessonIds.contains(lessonId)) {
      _completedLessonIds.add(lessonId);
      _completedLessonsCount++;
    }
    _totalPracticeMinutes += minutesRead;
    // Calculate new running average
    _averageFluencyScore = ((_averageFluencyScore * 4) + score) ~/ 5;
    
    // Increment streak for demonstration
    _streakDays++;
    notifyListeners();
  }
}
