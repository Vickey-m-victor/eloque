import 'dart:math';

enum AlignmentStatus { correct, mispronounced, skipped, filler }

class AlignedWord {
  final String text;
  final AlignmentStatus status;

  AlignedWord(this.text, this.status);
}

class AlignmentHelper {
  static const List<String> fillerWords = ['um', 'uh', 'like', 'you', 'know'];

  /// Cleans punctuation and converts a string to lowercase.
  static String clean(String word) {
    return word.replaceAll(RegExp(r'[.,!?()]'), '').toLowerCase().trim();
  }

  /// Aligns the target script words with the transcript words.
  static List<AlignedWord> align(String targetText, String transcriptText) {
    final List<String> targetWords = targetText
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    final List<String> transcriptWords = transcriptText
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (targetWords.isEmpty) {
      return transcriptWords
          .map((w) => AlignedWord(w, _isFiller(w) ? AlignmentStatus.filler : AlignmentStatus.mispronounced))
          .toList();
    }
    if (transcriptWords.isEmpty) {
      return targetWords
          .map((w) => AlignedWord(w, AlignmentStatus.skipped))
          .toList();
    }

    final int n = targetWords.length;
    final int m = transcriptWords.length;

    // dp[i][j] represents the alignment cost between targetWords[0..i-1] and transcriptWords[0..j-1]
    final List<List<double>> dp = List.generate(
      n + 1,
      (_) => List.filled(m + 1, 0.0),
    );

    // Initialization costs
    for (int i = 0; i <= n; i++) {
      dp[i][0] = i * 1.5; // Deletion/Skip cost
    }
    // Fix initial row indexing
    for (int j = 0; j <= m; j++) {
      dp[0][j] = j * 1.5; // Insertion/Extra spoken cost
    }

    // Alignment costs: Match = 0, Substitution = 2.0, Ins/Del = 1.5
    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        final bool isMatch = clean(targetWords[i - 1]) == clean(transcriptWords[j - 1]);
        if (isMatch) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          final double sub = dp[i - 1][j - 1] + 2.0; // Substitution (Mispronounced)
          final double del = dp[i - 1][j] + 1.5;     // Deletion (Skipped)
          final double ins = dp[i][j - 1] + 1.5;     // Insertion (Extra spoken)
          dp[i][j] = min(sub, min(del, ins));
        }
      }
    }

    // Backtracking to find the alignment path
    final List<AlignedWord> reversedResult = [];
    int i = n;
    int j = m;

    while (i > 0 || j > 0) {
      if (i > 0 && j > 0) {
        final bool isMatch = clean(targetWords[i - 1]) == clean(transcriptWords[j - 1]);
        if (isMatch) {
          reversedResult.add(AlignedWord(targetWords[i - 1], AlignmentStatus.correct));
          i--;
          j--;
          continue;
        }

        final double currentCost = dp[i][j];
        final double subCost = dp[i - 1][j - 1] + 2.0;
        final double delCost = dp[i - 1][j] + 1.5;

        // Choose path with minimum cost
        if (currentCost == subCost) {
          // Substitution: user spoke a different word (mispronounced)
          reversedResult.add(AlignedWord(transcriptWords[j - 1], AlignmentStatus.mispronounced));
          i--;
          j--;
        } else if (currentCost == delCost) {
          // Deletion: user skipped a word in the target script
          reversedResult.add(AlignedWord(targetWords[i - 1], AlignmentStatus.skipped));
          i--;
        } else {
          // Insertion: user spoke an extra word
          final String word = transcriptWords[j - 1];
          final bool isFiller = _isFiller(word);
          reversedResult.add(AlignedWord(word, isFiller ? AlignmentStatus.filler : AlignmentStatus.mispronounced));
          j--;
        }
      } else if (i > 0) {
        // Only target words left (skipped)
        reversedResult.add(AlignedWord(targetWords[i - 1], AlignmentStatus.skipped));
        i--;
      } else {
        // Only transcript words left (extra insertions)
        final String word = transcriptWords[j - 1];
        final bool isFiller = _isFiller(word);
        reversedResult.add(AlignedWord(word, isFiller ? AlignmentStatus.filler : AlignmentStatus.mispronounced));
        j--;
      }
    }

    return reversedResult.reversed.toList();
  }

  static bool _isFiller(String word) {
    return fillerWords.contains(clean(word));
  }
}
