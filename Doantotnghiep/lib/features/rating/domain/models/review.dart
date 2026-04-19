class Review {
  final String id;
  final String bookingId; // Link to specific booking
  final String tutorId;
  final String userId;
  final String userName;
  final String userAvatar;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final bool isVisible; // Blind Review Logic

  Review({
    required this.id,
    required this.bookingId,
    required this.tutorId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.isVisible = false,
  });

  Review copyWith({
    String? id,
    String? bookingId,
    String? tutorId,
    String? userId,
    String? userName,
    String? userAvatar,
    double? rating,
    String? comment,
    DateTime? createdAt,
    bool? isVisible,
  }) {
    return Review(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      tutorId: tutorId ?? this.tutorId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}
