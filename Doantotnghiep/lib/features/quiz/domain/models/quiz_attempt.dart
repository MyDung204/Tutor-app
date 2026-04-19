import 'quiz.dart';

class QuizAttempt {
  final int id;
  final int userId;
  final int quizId;
  final double score;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Quiz? quiz;

  QuizAttempt({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.score,
    required this.startedAt,
    this.completedAt,
    this.quiz,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'],
      userId: json['user_id'],
      quizId: json['quiz_id'],
      score: (json['score'] as num).toDouble(),
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      quiz: json['quiz'] != null ? Quiz.fromJson(json['quiz']) : null,
    );
  }
}
