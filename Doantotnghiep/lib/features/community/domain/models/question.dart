import 'package:doantotnghiep/features/community/domain/models/answer.dart';

class Question {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String subject;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final int likeCount;
  final int answerCount;
  final bool isSolved;
  final List<Answer> answers; // Nested answers for Mock

  Question({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.subject,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.likeCount = 0,
    this.answerCount = 0,
    this.isSolved = false,
    this.answers = const [],
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      userName: json['user_name'] ?? 'Người dùng',
      userAvatar: json['user_avatar'] ?? '',
      subject: json['subject'] ?? 'Chung',
      content: json['content'] ?? '',
      imageUrl: json['image_url'],
      // Handle Laravel Default Date Format or ISO
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now() 
          : DateTime.now(),
      likeCount: int.tryParse(json['like_count'].toString()) ?? 0,
      answerCount: int.tryParse(json['answer_count'].toString()) ?? 0,
      isSolved: json['is_solved'] == 1 || json['is_solved'] == true,
      answers: (json['answers'] as List<dynamic>?)
              ?.map((e) => Answer.fromJson(e))
              .toList() ??
          [],
    );
  }

  Question copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? subject,
    String? content,
    String? imageUrl,
    DateTime? createdAt,
    int? likeCount,
    int? answerCount,
    bool? isSolved,
    List<Answer>? answers,
  }) {
    return Question(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      subject: subject ?? this.subject,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      answerCount: answerCount ?? this.answerCount,
      isSolved: isSolved ?? this.isSolved,
      answers: answers ?? this.answers,
    );
  }
}
