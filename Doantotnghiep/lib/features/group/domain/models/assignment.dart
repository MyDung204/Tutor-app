
class Assignment {
  final int id;
  final int courseId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String? attachmentUrl;
  final DateTime createdAt;
  final int submissionCount;
  final bool isSubmitted;
  final AssignmentSubmission? mySubmission;

  Assignment({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    this.dueDate,
    this.attachmentUrl,
    required this.createdAt,
    this.submissionCount = 0,
    this.isSubmitted = false,
    this.mySubmission,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      courseId: json['course_id'] is String ? int.parse(json['course_id']) : json['course_id'],
      title: json['title'],
      description: json['description'],
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      attachmentUrl: json['attachment_url'],
      createdAt: DateTime.parse(json['created_at']),
      submissionCount: json['submissions_count'] != null 
          ? (json['submissions_count'] is String ? int.parse(json['submissions_count']) : json['submissions_count']) 
          : 0,
      isSubmitted: json['is_submitted'] ?? false,
      mySubmission: json['my_submission'] != null ? AssignmentSubmission.fromJson(json['my_submission']) : null,
    );
  }
}

class AssignmentSubmission {
  final int id;
  final int assignmentId;
  final int studentId;
  final String? content;
  final String? fileUrl;
  final DateTime submittedAt;
  final double? grade;
  final String? feedback;
  final StudentInfo? student;

  AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    this.content,
    this.fileUrl,
    required this.submittedAt,
    this.grade,
    this.feedback,
    this.student,
  });

  factory AssignmentSubmission.fromJson(Map<String, dynamic> json) {
    return AssignmentSubmission(
      id: json['id'],
      assignmentId: json['assignment_id'],
      studentId: json['student_id'],
      content: json['content'],
      fileUrl: json['file_url'],
      submittedAt: DateTime.parse(json['submitted_at']),
      grade: json['grade'] != null ? double.parse(json['grade'].toString()) : null,
      feedback: json['feedback'],
      student: json['student'] != null ? StudentInfo.fromJson(json['student']) : null,
    );
  }
}

class StudentInfo {
  final int id;
  final String name;
  final String? avatarUrl;

  StudentInfo({required this.id, required this.name, this.avatarUrl});

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      id: json['id'],
      name: json['name'],
      avatarUrl: json['avatar_url'],
    );
  }
}
