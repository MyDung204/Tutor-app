
class CourseOffer {
  final String id;
  final String tutorId;
  final String tutorName;
  final String subject;
  final String schedule;
  final double price;
  final int sessionsPerWeek;
  final String status; // 'pending', 'accepted', 'rejected'

  CourseOffer({
    required this.id,
    required this.tutorId,
    required this.tutorName,
    required this.subject,
    required this.schedule,
    required this.price,
    required this.sessionsPerWeek,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tutorId': tutorId,
      'tutorName': tutorName,
      'subject': subject,
      'schedule': schedule,
      'price': price,
      'sessionsPerWeek': sessionsPerWeek,
      'status': status,
    };
  }

  factory CourseOffer.fromMap(Map<String, dynamic> map) {
    return CourseOffer(
      id: map['id'] ?? '',
      tutorId: map['tutorId'] ?? '',
      tutorName: map['tutorName'] ?? '',
      subject: map['subject'] ?? '',
      schedule: map['schedule'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      sessionsPerWeek: map['sessionsPerWeek'] ?? 0,
      status: map['status'] ?? 'pending',
    );
  }
}
