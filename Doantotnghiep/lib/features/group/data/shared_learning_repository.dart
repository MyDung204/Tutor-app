/// Shared Learning Repository
/// 
/// Handles all shared learning operations:
/// - Study groups (Học ghép) - Group learning sessions
/// - Courses (Lớp học) - Tutor-created classes
/// - Group membership management
/// - Course enrollment
/// 
/// **Repository Pattern:**
/// - Abstracts API calls from business logic
/// - Centralizes data access
/// - Makes code testable (can mock repository)
/// 
/// **Error Handling:**
/// - Returns empty list/null on error (fails gracefully)
/// - Logs errors for debugging
/// - Prevents app crashes from API failures
library;

import 'package:doantotnghiep/core/network/api_client.dart';
import 'package:doantotnghiep/core/exceptions/app_exceptions.dart';
import 'package:doantotnghiep/features/group/domain/models/group_request.dart';
import 'package:doantotnghiep/features/group/domain/models/course.dart';
import 'package:doantotnghiep/features/group/domain/models/assignment.dart';
import 'package:doantotnghiep/features/group/domain/models/announcement.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for SharedLearningRepository
/// 
/// Creates a single repository instance shared across the app.
/// Automatically injects ApiClient dependency.
final sharedLearningRepositoryProvider = Provider<SharedLearningRepository>((ref) {
  return SharedLearningRepository(ref.watch(apiClientProvider));
});

/// Repository for shared learning features (Study Groups & Courses)
/// 
/// Manages all operations related to:
/// - Study groups (student-created learning groups)
/// - Courses (tutor-created classes)
/// - Membership and enrollment
class SharedLearningRepository {
  /// API client for making HTTP requests
  final ApiClient _client;

  /// Initialize repository with API client
  SharedLearningRepository(this._client);

  /// Get all available study groups
  /// 
  /// **Purpose:**
  /// - Fetches all open study groups from backend
  /// - Used for browsing available groups to join
  /// 
  /// **Returns:**
  /// - `List<GroupRequest>`: List of study groups (empty list on error)
  /// 
  /// **API Endpoint:**
  /// - `GET /study-groups`
  /// 
  /// **Error Handling:**
  /// - Returns empty list on error (fails gracefully)
  /// - Logs error for debugging
  /// 
  /// **Example:**
  /// ```dart
  /// final groups = await repository.getStudyGroups();
  /// // Display in list
  /// ```
  Future<List<GroupRequest>> getStudyGroups() async {
    try {
      final response = await _client.get('/study-groups');
      if (response is List) {
        return response.map((e) => GroupRequest.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching study groups: $e');
      return [];
    }
  }

  /// Get study groups that current user is a member of
  /// 
  /// **Purpose:**
  /// - Fetches groups where authenticated user is an approved member
  /// - Used for "My Groups" section on home screen
  /// 
  /// **Returns:**
  /// - `List<GroupRequest>`: List of user's study groups (empty list on error)
  /// 
  /// **API Endpoint:**
  /// - `GET /my-study-groups` (requires authentication)
  /// 
  /// **Error Handling:**
  /// - Handles ApiException separately for better error messages
  /// - Returns empty list to prevent app crash
  /// - UI handles empty state gracefully
  /// 
  /// **Example:**
  /// ```dart
  /// final myGroups = await repository.getMyStudyGroups();
  /// // Display in "My Groups" section
  /// ```
  Future<List<GroupRequest>> getMyStudyGroups() async {
    try {
      final response = await _client.get('/my-study-groups');
      if (response is List) {
        return response.map((e) => GroupRequest.fromJson(e)).toList();
      }
      return [];
    } on ApiException catch (e) {
      // Log user-friendly message
      print('Error fetching my study groups: ${e.userMessage}');
      // Return empty list to prevent app crash
      // UI will handle empty state gracefully
      return [];
    } catch (e) {
      print('Unexpected error fetching my study groups: $e');
      return [];
    }
  }

  /// Create a new study group
  /// 
  /// **Parameters:**
  /// - `req`: GroupRequest object with group details (topic, subject, etc.)
  /// 
  /// **Returns:**
  /// - `GroupRequest?`: Created group object, or null on error
  /// 
  /// **Purpose:**
  /// - Creates a new study group (Học ghép)
  /// - Creator is automatically added as approved member
  /// 
  /// **API Endpoint:**
  /// - `POST /study-groups` (requires authentication)
  /// 
  /// **Error Handling:**
  /// - Returns null on error
  /// - Logs error for debugging
  /// 
  /// **Example:**
  /// ```dart
  /// final group = await repository.createStudyGroup(groupRequest);
  /// if (group != null) {
  ///   // Group created successfully
  /// }
  /// ```
  Future<GroupRequest?> createStudyGroup(GroupRequest req) async {
    try {
      final response = await _client.post('/study-groups', data: {
        'topic': req.topic, 
        'subject': req.subject,
        'grade_level': req.gradeLevel,
        'max_members': req.maxMembers,
        'description': req.description,
        'location': req.location,
        'price': req.pricePerSession,
      });
      if (response != null) { // Assuming response is the JSON Map
         return GroupRequest.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error creating study group: $e');
      return null;
    }
  }

  Future<List<Course>> getCourses() async {
    try {
      final response = await _client.get('/courses');
      if (response is List) {
        return response.map((e) => Course.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching courses: $e');
      return [];
    }
  }
  /// Tạo lớp học mới
  /// 
  /// **Parameters:**
  /// - `data`: Map chứa thông tin lớp học (title, subject, grade_level, description, price, max_students, schedule, mode, address, start_date)
  /// 
  /// **Returns:**
  /// - `Course?`: Course object nếu thành công, null nếu thất bại
  /// 
  /// **Throws:**
  /// - `ApiException`: Nếu có lỗi từ API (validation, unauthorized, server error)
  /// 
  /// **Error Handling:**
  /// - Re-throw ApiException để UI có thể hiển thị message cho user
  /// - Log error để debug
  Future<Course?> createCourse(Map<String, dynamic> data) async {
    try {
      final response = await _client.post('/courses', data: data);
      if (response != null) {
        return Course.fromJson(response);
      }
      return null;
    } on ApiException {
      // Re-throw ApiException để UI có thể hiển thị message
      rethrow;
    } catch (e) {
      print('Unexpected error creating course: $e');
      // Wrap unexpected errors in ApiException
      throw ApiException(
        userMessage: 'Lỗi khi tạo lớp học. Vui lòng thử lại.',
        technicalMessage: e.toString(),
        originalError: e,
      );
    }
  }

  Future<bool> updateCourse(String id, Map<String, dynamic> data) async {
    try {
      await _client.put('/courses/$id', data: data);
      return true;
    } catch (e) {
      print('Error updating course: $e');
      return false;
    }
  }

  Future<List<dynamic>> getTutorRequests() async {
     try {
       final response = await _client.get('/tutor-requests');
       if (response is List) {
          return response;
       }
       return [];
     } catch (e) {
       print('Error fetching tutor requests: $e');
       return [];
     }
  }

  Future<List<dynamic>> getMyTutorRequests() async {
     try {
       final response = await _client.get('/my-tutor-requests');
       if (response is List) {
          return response;
       }
       return [];
     } catch (e) {
       print('Error fetching my tutor requests: $e');
       return [];
     }
  }

  Future<bool> deleteTutorRequest(String id) async {
    try {
      await _client.delete('/tutor-requests/$id');
      return true;
    } catch (e) {
      print('Error deleting tutor request: $e');
      return false;
    }
  }

  Future<bool> deleteCourse(String id) async {
    try {
      await _client.delete('/courses/$id');
      return true;
    } catch (e) {
      print('Error deleting course: $e');
      return false;
    }
  }
  /// Đăng ký lớp học
  /// 
  /// **Parameters:**
  /// - `id`: Course ID
  /// 
  /// **Returns:**
  /// - `bool`: true nếu đăng ký thành công, false nếu thất bại
  /// 
  /// **Error Handling:**
  /// - Kiểm tra xem user đã đăng ký chưa
  /// - Kiểm tra lớp học còn chỗ không
  /// - Hiển thị message lỗi rõ ràng
  Future<bool> joinCourse(String id, {String paymentType = 'full'}) async {
    try {
      await _client.post('/courses/$id/join', data: {'payment_type': paymentType});
      return true;
    } on ApiException catch (e) {
      // ApiException đã có userMessage, chỉ cần log
      print('Error joining course: ${e.userMessage}');
      return false;
    } catch (e) {
      print('Error joining course: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> refuseTuition(String courseId) async {
     try {
       final response = await _client.post('/courses/$courseId/tuition/refuse');
       return response as Map<String, dynamic>?;
     } catch (e) {
       print('Error refusing tuition: $e');
       return null;
     }
  }

  Future<List<Course>> getMyCourses() async {
     try {
       final response = await _client.get('/my-courses');
       if (response is List) {
         return response.map((e) => Course.fromJson(e)).toList();
       }
       return [];
     } catch (e) {
       print('Error fetching my courses: $e');
       return [];
     }
  }

  Future<bool> leaveCourse(String id) async {
    try {
      await _client.post('/courses/$id/leave');
      return true;
    } catch (e) {
      print('Error leaving course: $e');
      return false;
    }
  }

  Future<String?> kickStudent(String courseId, String studentId, int sessionsStudied, {int totalSessions = 10, String reason = ''}) async {
    try {
      final response = await _client.post('/courses/$courseId/kick', data: {
        'student_id': studentId,
        'sessions_studied': sessionsStudied,
        'total_sessions': totalSessions,
        'reason': reason,
      });
      if (response != null && response['message'] != null) {
        return response['message'].toString();
      }
      return 'Đã xóa học viên thành công (Không có phản hồi chi tiết)';
    } on ApiException catch (e) {
       // Return error message directly to UI
       return 'Lỗi: ${e.userMessage}';
    } catch (e) {
      print('Error kicking student: $e');
      return 'Lỗi hệ thống khi xóa học viên.';
    }
  }

  Future<bool> removeStudentFromCourse(String courseId, String studentId) async {
    // Deprecated or Used for simple removal?
    // Let's keep it but favor kickStudent for Courses
    try {
      await _client.delete('/courses/$courseId/students/$studentId');
      return true;
    } catch (e) {
      print('Error removing student from course: $e');
      return false;
    }
  }

  Future<bool> joinGroup(String id) async {
    try {
      await _client.post('/study-groups/$id/join');
      return true;
    } catch (e) {
      print('Error joining group: $e');
      return false;
    }
  }

  Future<bool> approveMember(String groupId, String userId) async {
    try {
      await _client.post('/study-groups/$groupId/members/$userId/approve');
      return true;
    } catch (e) {
      print('Error approving member: $e');
      return false;
    }
  }

  Future<bool> rejectMember(String groupId, String userId) async {
    try {
      await _client.post('/study-groups/$groupId/members/$userId/reject');
      return true;
    } catch (e) {
      print('Error rejecting member: $e');
      return false;
    }
  }

  Future<bool> leaveGroup(String id) async {
    try {
      await _client.post('/study-groups/$id/leave');
      return true;
    } catch (e) {
      print('Error leaving group: $e');
      return false;
    }
  }

  Future<List<dynamic>> getGroupMembers(String id) async {
    try {
      final response = await _client.get('/study-groups/$id/members');
      if (response is List) return response;
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- Announcements ---
  Future<List<Announcement>> getAnnouncements(String courseId) async {
    try {
      final response = await _client.get('/courses/$courseId/announcements');
      if (response is List) {
        return response.map((e) => Announcement.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching announcements: $e');
      return [];
    }
  }

  Future<Announcement?> createAnnouncement(String courseId, String content) async {
    try {
      final response = await _client.post('/courses/$courseId/announcements', data: {
        'content': content,
      });
      if (response != null) {
        return Announcement.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error creating announcement: $e');
      return null;
    }
  }

  Future<bool> removeMember(String groupId, String userId) async {
    try {
      await _client.delete('/study-groups/$groupId/members/$userId');
      return true;
    } catch (e) {
      print('Error removing member: $e');
      return false;
    }
  }

  Future<bool> updateGroup(String id, Map<String, dynamic> data) async {
    try {
      await _client.put('/study-groups/$id', data: data);
      return true;
    } catch (e) {
      print('Error updating group: $e');
      return false;
    }
  }

  Future<bool> deleteGroup(String id) async {
    try {
      await _client.delete('/study-groups/$id');
      return true;
    } catch (e) {
      print('Error deleting group: $e');
      return false;
    }
  }

  Future<List<Assignment>> getAssignments(int courseId) async {
    try {
      final response = await _client.get('/courses/$courseId/assignments');
      if (response is List) {
        return response.map((e) => Assignment.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching assignments: $e');
      return [];
    }
  }

  Future<Assignment?> createAssignment(Map<String, dynamic> data) async {
    try {
      final response = await _client.post('/assignments', data: data);
      if (response != null) {
        return Assignment.fromJson(response);
      }
      return null;
    } on ApiException {
      rethrow;
    } catch (e) {
      print('Error creating assignment: $e');
      return null;
    }
  }

  Future<bool> deleteAssignment(int id) async {
    try {
      await _client.delete('/assignments/$id');
      return true;
    } catch (e) {
      print('Error deleting assignment: $e');
      return false;
    }
  }

  Future<AssignmentSubmission?> submitAssignment(int assignmentId, String? content, String? fileUrl) async {
    try {
      final response = await _client.post('/assignments/$assignmentId/submit', data: {
        'content': content,
        'file_url': fileUrl,
      });
      if (response != null) {
        return AssignmentSubmission.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error submitting assignment: $e');
      return null;
    }
  }

  Future<List<AssignmentSubmission>> getAssignmentSubmissions(int assignmentId) async {
    try {
      final response = await _client.get('/assignments/$assignmentId/submissions');
      if (response is List) {
        return response.map((e) => AssignmentSubmission.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching submissions: $e');
      return [];
    }
  }

  // Smart Matching
  Future<List<dynamic>> getMatchingTutorsForRequest(String requestId) async {
    try {
      final response = await _client.get('/smart-matching/request/$requestId');
      if (response is List) return response;
      return [];
    } catch (e) {
      print('Error matching tutors: $e');
      return [];
    }
  }

  Future<List<dynamic>> getMatchingRequestsForTutor() async {
    try {
      final response = await _client.get('/smart-matching/tutor');
      if (response is List) return response;
      return [];
    } catch (e) {
      print('Error matching requests: $e');
      return [];
    }
  }
}
