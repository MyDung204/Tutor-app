/// App Notification Model
/// 
/// Represents a notification from FCM or Firestore.
class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final bool isRead;
  final String type; // 'booking', 'message', 'reminder', 'promotion', 'system'
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
    required this.type,
    this.data,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    // Handle Firestore Timestamp or ISO String
    DateTime parsedTime = DateTime.now();
    if (map['createdAt'] != null) {
      if (map['createdAt'] is String) {
        parsedTime = DateTime.parse(map['createdAt']);
      } else { // Assume Firestore Timestamp
        try {
           parsedTime = (map['createdAt']).toDate();
        } catch (e) {
           parsedTime = DateTime.now();
        }
      }
    } else if (map['created_at'] != null) {
       parsedTime = DateTime.parse(map['created_at']);
    }

    return AppNotification(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      time: parsedTime,
      isRead: map['isRead'] ?? map['is_read'] ?? false,
      type: map['type'] ?? 'system',
      data: (map['data'] is Map<String, dynamic>)
          ? map['data']
          : (map['data'] is List ? <String, dynamic>{} : null),
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification.fromMap(json, json['id'].toString());
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'createdAt': time,
      'isRead': isRead,
      'type': type,
      'data': data,
    };
  }
}
