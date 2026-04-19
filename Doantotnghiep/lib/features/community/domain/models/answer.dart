
class Answer {
  final String id;
  final String questionId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final int likeCount;
  final bool isAcccepted; // If this answer solved the question

  Answer({
    required this.id,
    required this.questionId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.likeCount = 0,
    this.isAcccepted = false,
  });
  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'].toString(),
      questionId: json['question_id'].toString(),
      userId: json['user_id'].toString(),
      userName: json['user_name'] ?? 'Người dùng',
      userAvatar: json['user_avatar'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['image_url'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now() 
          : DateTime.now(),
      likeCount: int.tryParse(json['like_count'].toString()) ?? 0,
      isAcccepted: json['is_accepted'] == 1 || json['is_accepted'] == true,
    );
  }
}
