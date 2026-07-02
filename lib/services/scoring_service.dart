import 'dart:math';
import '../models/lesson.dart';
import '../models/practice_result.dart';

class ScoringService {
  // Configurable weights for Conversational Track
  static const double convAccuracyWeight = 0.70;
  static const double convPaceWeight = 0.20;
  static const double convFillerWeight = 0.10;

  // Configurable weights for Interview Prep Track
  static const double intPrepPaceWeight = 0.60;
  static const double intPrepFillerWeight = 0.40;

  // Natural WPM target range boundaries
  static const int minTargetWpm = 130;
  static const int maxTargetWpm = 160;

  // List of filler words/phrases to match against (in lowercase)
  static const List<String> fillerWords = ['um', 'uh', 'like', 'you know'];

  /// Computes the speech scores and returns a complete PracticeResult.
  PracticeResult score({
    required Lesson lesson,
    required String transcript,
    required Duration sessionDuration,
    required String audioFilePath,
    required int targetWpm,
  }) {
    final String cleanTranscript = transcript.trim().toLowerCase();
    final List<String> transcriptWords = cleanTranscript
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    // 1. Calculate Actual WPM
    final int wordCount = transcriptWords.length;
    final double durationMinutes = sessionDuration.inMilliseconds / 60000.0;
    final int actualWpm = durationMinutes > 0 ? (wordCount / durationMinutes).round() : 0;

    // 2. Count Filler Words
    int fillerCount = 0;
    // Check single word fillers
    for (final word in transcriptWords) {
      if (fillerWords.contains(word)) {
        fillerCount++;
      }
    }
    // Check phrase fillers like "you know"
    final String lowercaseText = transcript.toLowerCase();
    for (final filler in fillerWords) {
      if (filler.contains(' ')) {
        // Find occurrences of multi-word filler phrase
        int index = 0;
        while ((index = lowercaseText.indexOf(filler, index)) != -1) {
          fillerCount++;
          index += filler.length;
        }
      }
    }

    // 3. Calculate Pace Score (0 to 100)
    double paceScore = 100.0;
    if (actualWpm < minTargetWpm) {
      // Deduct points for speaking too slowly
      paceScore = max(0.0, 100.0 - (minTargetWpm - actualWpm) * 1.5);
    } else if (actualWpm > maxTargetWpm) {
      // Deduct points for speaking too fast
      paceScore = max(0.0, 100.0 - (actualWpm - maxTargetWpm) * 1.5);
    }

    // 4. Calculate Filler Penalty Score (0 to 100)
    // 0 fillers = 100 score; each filler deducts 10 points
    final double fillerScore = max(0.0, 100.0 - (fillerCount * 10.0));

    double accuracyScore = 0.0;
    double fluencyScore = 0.0;

    if (lesson.track == LessonTrack.conversational) {
      // Conversational: calculate Levenshtein-based accuracy against original lesson text
      final List<String> targetWords = lesson.content
          .replaceAll(RegExp(r'[.,!?()]'), '')
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();

      final int distance = _levenshteinDistance(targetWords, transcriptWords);
      final int maxLen = max(targetWords.length, transcriptWords.length);
      accuracyScore = maxLen > 0 
          ? ((1.0 - (distance / maxLen)) * 100.0).clamp(0.0, 100.0)
          : 100.0;

      // Composite fluency score for Conversational track
      fluencyScore = (accuracyScore * convAccuracyWeight) +
          (paceScore * convPaceWeight) +
          (fillerScore * convFillerWeight);
    } else {
      // Interview Prep: No fixed target scripts. Accuracy set to 100 (not scored against source).
      accuracyScore = 100.0;

      // Composite fluency score for Interview Prep track (weighted pace and filler count)
      fluencyScore = (paceScore * intPrepPaceWeight) + (fillerScore * intPrepFillerWeight);
    }

    // Generate unique ID based on timestamp
    final String resultId = 'res_${DateTime.now().millisecondsSinceEpoch}';

    return PracticeResult(
      id: resultId,
      lessonId: lesson.id,
      audioFilePath: audioFilePath,
      transcript: transcript,
      completedAt: DateTime.now(),
      sessionDuration: sessionDuration,
      targetWpm: targetWpm,
      actualWpm: actualWpm,
      accuracyScore: double.parse(accuracyScore.toStringAsFixed(1)),
      fillerWordCount: fillerCount,
      fluencyScore: double.parse(fluencyScore.toStringAsFixed(1)),
    );
  }

  /// Calculates the Levenshtein distance between two string arrays.
  int _levenshteinDistance(List<String> s, List<String> t) {
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = _min3(v1[j] + 1, v0[j + 1] + 1, v0[j] + cost);
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[t.length];
  }

  int _min3(int a, int b, int c) => a < b ? (a < c ? a : c) : (b < c ? b : c);
}
