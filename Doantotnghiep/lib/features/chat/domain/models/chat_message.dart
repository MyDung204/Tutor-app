import 'package:doantotnghiep/features/chat/domain/models/course_offer.dart';

class ChatMessage {
  final dynamic id; // Changed from int? to dynamic to support String Firestore IDs
  final String text;
  final bool isUser;
  final DateTime time;
  final bool isSystem;
  final CourseOffer? offer;
  final bool isRead; // Added missing field
  final String? attachmentUrl;
  final String? attachmentType; // 'image' or 'file'
  final String? attachmentName;
  final int? bookingId;
  final String? senderName;
  final String? senderId;

  ChatMessage({
    this.id,
    required this.text,
    required this.isUser,
    required this.time,
    this.isSystem = false,
    this.offer,
    this.isRead = false,
    this.attachmentUrl,
    this.attachmentType,
    this.attachmentName,
    this.bookingId,
    this.senderName,
    this.senderId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, int currentUserId) {
    // Existing Rest API FromJson
    final senderId = json['sender_id'].toString();
    final currentIdStr = currentUserId.toString();
    final isUser = senderId == currentIdStr;

    String? url = json['attachment_url'];
    if (url != null && url.contains('localhost')) {
       url = url.replaceFirst('localhost', '10.0.2.2');
    }

    return ChatMessage(
      id: json['id'],
      text: json['content'] ?? '',
      isUser: isUser,
      time: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      isSystem: false,
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      attachmentUrl: url,
      attachmentType: json['type'] == 'text' ? null : json['type'],
      attachmentName: json['attachment_name'],
      bookingId: json['booking_id'],
      senderName: json['sender_name'], // If API sends it
      senderId: senderId,
    );
  }

  // New Factory for Firestore
  factory ChatMessage.fromFirestore(Map<String, dynamic> data, String id, String currentUserId) {
    final senderId = data['sender_id'].toString();
    final isUser = senderId == currentUserId;
    
    // Handle Timestamp
    DateTime time = DateTime.now();
    if (data['created_at'] != null) {
      // cloud_firestore field
      try {
        time = data['created_at'].toDate();
      } catch (e) {
        time = DateTime.now();
      }
    }

    return ChatMessage(
      id: id, // String ID now
      text: data['content'] ?? '',
      isUser: isUser,
      time: time,
      isSystem: false,
      isRead: data['is_read'] == true,
      attachmentUrl: data['attachment_url'],
      attachmentType: data['type'] == 'text' ? null : data['type'],
      attachmentName: data['attachment_name'],
      offer: data['offer'] != null ? CourseOffer.fromMap(data['offer']) : null,
      senderName: data['sender_name'],
      senderId: senderId,
    );
  }
}

