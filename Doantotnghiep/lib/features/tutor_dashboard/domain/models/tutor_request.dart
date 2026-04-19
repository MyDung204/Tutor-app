
class TutorRequest {
  final String id;
  final String studentId;
  final String studentName;
  final String subject;
  final String gradeLevel;
  final double minBudget;
  final double maxBudget;
  final String schedule; // e.g. "Mon, Wed, Fri 18:00"
  final String description;
  final String location;
  final DateTime createdAt;
  final String status; // 'open', 'closed'

  TutorRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.subject,
    required this.gradeLevel,
    required this.minBudget,
    required this.maxBudget,
    required this.schedule,
    required this.description,
    required this.location,
    required this.createdAt,
    this.status = 'open',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'subject': subject,
      'grade_level': gradeLevel,
      'min_budget': minBudget,
      'max_budget': maxBudget,
      'schedule': schedule,
      'description': description,
      'location': location,
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }

  factory TutorRequest.fromJson(Map<String, dynamic> json) {
    return TutorRequest(
      id: json['id'].toString(),
      studentId: json['student_id']?.toString() ?? '',
      studentName: json['student'] != null ? json['student']['name'] ?? 'Học viên' : 'Học viên',
      subject: json['subject'] ?? '',
      gradeLevel: json['grade_level'] ?? '',
      minBudget: double.tryParse(json['min_budget'].toString()) ?? 0.0,
      maxBudget: double.tryParse(json['max_budget'].toString()) ?? 0.0,
      schedule: json['schedule'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now() 
          : DateTime.now(),
      status: json['status'] ?? 'open',
    );
  }

  factory TutorRequest.fromMap(Map<String, dynamic> map) => TutorRequest.fromJson(map);
}
