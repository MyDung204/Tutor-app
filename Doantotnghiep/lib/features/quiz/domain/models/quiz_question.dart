import 'quiz_option.dart';

class QuizQuestion {
  final int? id; // Nullable for creation
  final String content;
  final int points;
  final List<QuizOption> options;

  QuizQuestion({
    this.id,
    required this.content,
    this.points = 1,
    required this.options,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      content: json['content'],
      points: json['points'] ?? 1,
      options: (json['options'] as List?)
              ?.map((e) => QuizOption.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'points': points,
      'options': options.map((e) => e.toJson()).toList(),
    };
  }
}
