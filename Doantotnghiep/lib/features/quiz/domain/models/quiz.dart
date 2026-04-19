import 'package:doantotnghiep/features/tutor/domain/models/tutor.dart';
import 'quiz_question.dart';

class Quiz {
  final int id;
  final int tutorId;
  final String title;
  final String? description;
  final int? timeLimitMinutes;
  final bool isPublished;
  final List<QuizQuestion> questions;
  final Tutor? tutor;

  Quiz({
    required this.id,
    required this.tutorId,
    required this.title,
    this.description,
    this.timeLimitMinutes,
    required this.isPublished,
    this.questions = const [],
    this.tutor,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      tutorId: json['tutor_id'],
      title: json['title'],
      description: json['description'],
      timeLimitMinutes: json['time_limit_minutes'],
      isPublished: json['is_published'] == 1 || json['is_published'] == true,
      questions: (json['questions'] as List?)
              ?.map((e) => QuizQuestion.fromJson(e))
              .toList() ??
          [],
      tutor: json['tutor'] != null ? Tutor.fromJson(json['tutor']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tutor_id': tutorId,
      'title': title,
      'description': description,
      'time_limit_minutes': timeLimitMinutes,
      'is_published': isPublished,
      'questions': questions.map((e) => e.toJson()).toList(),
    };
  }
}
