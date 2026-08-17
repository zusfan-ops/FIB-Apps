class JlptMockResult {
  final int id;
  final String level;
  final int totalQuestions;
  final int correctCount;
  final int score;
  final int? durationSeconds;
  final String? createdAt;

  const JlptMockResult({
    required this.id,
    required this.level,
    required this.totalQuestions,
    required this.correctCount,
    required this.score,
    this.durationSeconds,
    this.createdAt,
  });

  factory JlptMockResult.fromJson(Map<String, dynamic> json) {
    return JlptMockResult(
      id: json['id'] as int,
      level: json['level'] as String? ?? 'N5',
      totalQuestions: json['total_questions'] as int? ?? 0,
      correctCount: json['correct_count'] as int? ?? 0,
      score: json['score'] as int? ?? 0,
      durationSeconds: json['duration_seconds'] as int?,
      createdAt: json['created_at'] as String?,
    );
  }
}
