import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../utils/dummy_data.dart';

class LessonProvider with ChangeNotifier {
  final List<Lesson> _lessons = dummyLessons;
  String _selectedCategory = 'All';
  String _selectedDifficulty = 'All';
  LessonTrack? _selectedTrack; // Track filter (null means all tracks)
  Lesson? _selectedLesson;

  // Getters for filtering
  String get selectedCategory => _selectedCategory;
  String get selectedDifficulty => _selectedDifficulty;
  LessonTrack? get selectedTrack => _selectedTrack;
  Lesson? get selectedLesson => _selectedLesson;

  // Filtered lessons
  List<Lesson> get lessons {
    return _lessons.where((lesson) {
      final matchesCategory = _selectedCategory == 'All' || lesson.category == _selectedCategory;
      final matchesDifficulty = _selectedDifficulty == 'All' || lesson.difficulty == _selectedDifficulty;
      final matchesTrack = _selectedTrack == null || lesson.track == _selectedTrack;
      return matchesCategory && matchesDifficulty && matchesTrack;
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

  void selectTrack(LessonTrack? track) {
    if (_selectedTrack != track) {
      _selectedTrack = track;
      notifyListeners();
    }
  }

  void selectLesson(Lesson? lesson) {
    _selectedLesson = lesson;
    notifyListeners();
  }
}
