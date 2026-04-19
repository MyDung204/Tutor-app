class QuizOption {
  final int? id; // Nullable for creation
  final String content;
  final bool? isCorrect; // Nullable because hidden for students

  QuizOption({
    this.id,
    required this.content,
    this.isCorrect,
  });

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      id: json['id'],
      content: json['content'],
      isCorrect: json['is_correct'] != null 
          ? (json['is_correct'] == 1 || json['is_correct'] == true) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'is_correct': isCorrect,
    };
  }
}
