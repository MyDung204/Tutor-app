class Announcement {
  final int id;
  final int courseId;
  final int userId;
  final String content;
  final DateTime createdAt;
  final User? author;

  Announcement({
    required this.id,
    required this.courseId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.author,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      courseId: json['course_id'],
      userId: json['user_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      author: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}

class User {
  final int id;
  final String name;
  final String? avatarUrl;

  User({required this.id, required this.name, this.avatarUrl});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? 'Giảng viên',
      avatarUrl: json['avatar_url'],
    );
  }
}
