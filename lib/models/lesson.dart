enum LessonTrack {
  conversational,
  interviewPrep,
}

class Lesson {
  final String id;
  final String title;
  final String description;
  final String content;
  final String category;
  final String difficulty; // 'Beginner', 'Intermediate', 'Advanced'
  final int estimatedMinutes;
  final LessonTrack track;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.category,
    required this.difficulty,
    required this.estimatedMinutes,
    this.track = LessonTrack.conversational,
  });

  List<String> get sentences {
    // Split sentences using lookbehind for punctuation followed by space
    final RegExp regex = RegExp(r'(?<=[.!?])\s+');
    return content
        .split(regex)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
