class Course {
  final String id;
  final String tutorId;
  final String tutorName;
  final String title;
  final String description;
  final double price;
  final int maxStudents;
  final DateTime startDate;
  final String schedule;
  final String status;
  final String subject; // Môn học
  final String gradeLevel; // Cấp độ
  final String mode; // Hình thức học (Online/Offline)
  final String? address; // Địa chỉ (nếu Offline)
  final List<Map<String, dynamic>> students; // Danh sách học viên (chỉ có khi là tutor)
  final bool isEnrolled;
  final int? studentCount; // Số lượng học viên (dành cho student view)
  final String? meetingLink;
  final String? tutorPhone;
  final bool isTutor;
  final String? tutorUserId;

  Course({
    required this.id,
    required this.tutorId,
    required this.tutorName,
    required this.title,
    required this.description,
    required this.price,
    required this.maxStudents,
    required this.startDate,
    required this.schedule,
    required this.status,
    required this.subject,
    required this.gradeLevel,
    this.mode = 'Offline',
    this.address,
    this.students = const [],
    this.isEnrolled = false,
    this.meetingLink,
    this.studentCount,
    this.tutorPhone,
    this.isTutor = false,
    this.tutorUserId,
    this.paymentStatus,
    this.gracePeriodEndsAt,
    this.graceRemainingSeconds,
  });

  final String? paymentStatus;
  final DateTime? gracePeriodEndsAt;
  final int? graceRemainingSeconds;

  // Helper getter to get accurate count regardless of view role
  int get currentStudentCount => students.isNotEmpty ? students.length : (studentCount ?? 0);

  factory Course.fromJson(Map<String, dynamic> json) {
    // Parse start_date - hỗ trợ nhiều format
    DateTime parseStartDate() {
      if (json['start_date'] == null) return DateTime.now();
      
      try {
        // Thử parse ISO format trước
        return DateTime.parse(json['start_date'].toString());
      } catch (e) {
        // Nếu không được, thử parse format Y-m-d
        try {
          final dateStr = json['start_date'].toString();
          if (dateStr.contains('T')) {
            return DateTime.parse(dateStr);
          } else {
            // Format: YYYY-MM-DD
            final parts = dateStr.split('-');
            if (parts.length == 3) {
              return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            }
          }
        } catch (e2) {
          print('Error parsing start_date: $e2');
        }
      }
      return DateTime.now();
    }
    
    return Course(
      id: json['id'].toString(),
      tutorId: json['tutor_id']?.toString() ?? '',
      tutorName: json['tutor']?['name'] ?? json['tutor_name'] ?? 'Giảng viên',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      maxStudents: int.tryParse(json['max_students'].toString()) ?? 0,
      startDate: parseStartDate(),
      schedule: json['schedule'] ?? '',
      status: json['status'] ?? 'open',
      mode: json['mode'] ?? 'Offline',
      address: json['address'],
      subject: json['subject'] ?? '',
      gradeLevel: json['grade_level'] ?? '',
      students: (json['students'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
      isEnrolled: json['is_enrolled'] == true || json['is_enrolled'] == 1,
      meetingLink: json['meeting_link'],
      studentCount: int.tryParse(json['student_count'].toString()),
      tutorPhone: json['tutor']?['phone'] ?? json['tutor']?['user']?['phone_number'] ?? json['tutor']?['phone_number'],
      isTutor: json['is_tutor'] == true || json['is_tutor'] == 1,
      tutorUserId: json['tutor']?['user_id']?.toString(),
      paymentStatus: json['payment_status'],
      gracePeriodEndsAt: json['grace_period_ends_at'] != null ? DateTime.tryParse(json['grace_period_ends_at']) : null,
      graceRemainingSeconds: int.tryParse(json['grace_remaining_seconds'].toString()),
    );
  }
}
