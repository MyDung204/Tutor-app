import 'package:doantotnghiep/features/chat/domain/models/course_offer.dart';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final CourseOffer? offer; // Optional: for 'context' passing

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.offer,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'].toString(),
      conversationId: json['conversation_id'].toString(),
      senderId: json['sender_id'].toString(),
      content: json['content'] ?? '',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      // offer: ... parse if needed
    );
  }
}
