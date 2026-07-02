class PracticeResult {
  final String id;
  final String lessonId;
  final String audioFilePath;
  final String transcript;
  final DateTime completedAt;
  final Duration sessionDuration;
  final int targetWpm;
  final int actualWpm;
  final double accuracyScore;
  final int fillerWordCount;
  final double fluencyScore;

  PracticeResult({
    required this.id,
    required this.lessonId,
    required this.audioFilePath,
    required this.transcript,
    required this.completedAt,
    required this.sessionDuration,
    required this.targetWpm,
    required this.actualWpm,
    required this.accuracyScore,
    required this.fillerWordCount,
    required this.fluencyScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lessonId': lessonId,
      'audioFilePath': audioFilePath,
      'transcript': transcript,
      'completedAt': completedAt.toIso8601String(),
      'sessionDurationMs': sessionDuration.inMilliseconds,
      'targetWpm': targetWpm,
      'actualWpm': actualWpm,
      'accuracyScore': accuracyScore,
      'fillerWordCount': fillerWordCount,
      'fluencyScore': fluencyScore,
    };
  }

  factory PracticeResult.fromJson(Map<String, dynamic> json) {
    return PracticeResult(
      id: json['id'] as String,
      lessonId: json['lessonId'] as String,
      audioFilePath: json['audioFilePath'] as String,
      transcript: json['transcript'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      sessionDuration: Duration(milliseconds: json['sessionDurationMs'] as int),
      targetWpm: json['targetWpm'] as int,
      actualWpm: json['actualWpm'] as int,
      accuracyScore: (json['accuracyScore'] as num).toDouble(),
      fillerWordCount: json['fillerWordCount'] as int,
      fluencyScore: (json['fluencyScore'] as num).toDouble(),
    );
  }
}
