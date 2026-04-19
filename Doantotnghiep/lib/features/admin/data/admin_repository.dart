/// Admin Repository
/// 
/// **Purpose:**
/// - Quản lý tất cả các API calls liên quan đến admin
/// - Bao gồm: stats, users, tutors, reports, audit logs
/// 
/// **Repository Pattern:**
/// - Abstracts API calls from business logic
/// - Centralizes data access
/// - Makes code testable (can mock repository)
/// 
/// **Error Handling:**
/// - Returns empty list/empty map on error (fails gracefully)
/// - Logs errors for debugging
/// - Prevents app crashes from API failures
library;

import 'package:doantotnghiep/core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider cho AdminRepository
/// 
/// Creates a single repository instance shared across the app.
/// Automatically injects ApiClient dependency.
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(apiClientProvider));
});

/// Repository cho các chức năng admin
/// 
/// Manages all operations related to:
/// - Dashboard statistics
/// - User management
/// - Tutor approval
/// - Report management
/// - Audit logs
class AdminRepository {
  /// API client for making HTTP requests
  final ApiClient _client;

  /// Initialize repository with API client
  AdminRepository(this._client);

  /// Lấy thống kê tổng quan cho dashboard
  /// 
  /// **Purpose:**
  /// - Fetches dashboard statistics from backend
  /// - Includes: total_revenue, total_users, total_tutors, pending_tutors, activities
  /// 
  /// **Returns:**
  /// - `Map<String, dynamic>`: Stats object (empty map on error)
  /// 
  /// **API Endpoint:**
  /// - `GET /admin/stats`
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _client.get('/admin/stats');
      if (response is Map<String, dynamic>) {
        return response;
      }
      return {};
    } catch (e) {
      print('Error fetching admin stats: $e');
      return {};
    }
  }

  /// Lấy danh sách người dùng với filter
  /// 
  /// **Purpose:**
  /// - Fetches users list from backend with optional search and role filter
  /// - Used in AdminUsersScreen
  /// 
  /// **Parameters:**
  /// - `search`: Search query (name, email) - optional
  /// - `role`: Role filter ('All', 'Gia sư', 'Học viên') - optional
  /// 
  /// **Returns:**
  /// - `List<dynamic>`: List of user objects (empty list on error)
  /// 
  /// **API Endpoint:**
  /// - `GET /admin/users?search=...&role=...`
  Future<List<dynamic>> getUsers({String? search, String? role}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (role != null && role != 'All') {
        // Convert Vietnamese role to API role
        queryParams['role'] = role == 'Gia sư' ? 'tutor' : 'student';
      }

      final response = await _client.get('/admin/users', queryParameters: queryParams);
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        return response['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getUser(int userId) async {
    try {
      final response = await _client.get('/admin/users/$userId');
      if (response is Map<String, dynamic>) {
        return response;
      }
      return null;
    } catch (e) {
      print('Error fetching user detail: $e');
      return null;
    }
  }

  Future<bool> updateUser(int userId, Map<String, dynamic> data) async {
    try {
      await _client.put('/admin/users/$userId', data: data);
      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  /// Khóa/Mở khóa tài khoản người dùng
  /// 
  /// **Purpose:**
  /// - Toggle ban status của user
  /// - Nếu user đang active → ban
  /// - Nếu user đang banned → unban
  /// 
  /// **Parameters:**
  /// - `userId`: ID của user cần toggle ban
  /// 
  /// **Returns:**
  /// - `bool`: true nếu thành công, false nếu thất bại
  /// 
  /// **API Endpoint:**
  /// - `POST /admin/users/{userId}/ban`
  Future<bool> toggleBan(int userId) async {
    try {
      await _client.post('/admin/users/$userId/ban', data: {});
      return true;
    } catch (e) {
      print('Error banning user: $e');
      return false;
    }
  }

  Future<List<dynamic>> getTutorRequests() async {
    try {
      final response = await _client.get('/admin/tutor-requests');
      if (response is List) {
        return response;
      }
      return [];
    } catch (e) {
      print('Error fetching tutor requests: $e');
      return [];
    }
  }

  Future<bool> approveTutor(int tutorId) async {
    try {
      await _client.post('/admin/tutors/$tutorId/approve', data: {});
      return true;
    } catch (e) {
      print('Error approving tutor: $e');
      return false;
    }
  }

  Future<bool> rejectTutor(int tutorId) async {
    try {
      await _client.post('/admin/tutors/$tutorId/reject', data: {});
      return true;
    } catch (e) {
      print('Error rejecting tutor: $e');
      return false;
    }
  }

  Future<List<dynamic>> getReports() async {
    try {
      final response = await _client.get('/admin/reports');
      if (response is List) {
        return response;
      }
      return [];
    } catch (e) {
      print('Error fetching reports: $e');
      return [];
    }
  }

  Future<bool> resolveReport(int reportId) async {
    try {
      await _client.post('/admin/reports/$reportId/resolve', data: {});
      return true;
    } catch (e) {
      print('Error resolving report: $e');
      return false;
    }
  }
  Future<List<dynamic>> getAuditLogs({String type = 'alert'}) async {
    try {
      final response = await _client.get('/admin/audit-logs', queryParameters: {'type': type});
      if (response is List) {
        return response;
      }
      return [];
    } catch (e) {
      print('Error fetching audit logs: $e');
      return [];
    }
  }

  // --- Course Approval ---
  Future<List<dynamic>> getPendingCourses() async {
    try {
      final response = await _client.get('/admin/courses/pending');
      if (response is List) {
        return response;
      }
      return [];
    } catch (e) {
      print('Error fetching pending courses: $e');
      return [];
    }
  }

  Future<bool> approveCourse(int courseId) async {
    try {
      await _client.post('/admin/courses/$courseId/approve', data: {});
      return true;
    } catch (e) {
      print('Error approving course: $e');
      return false;
    }
  }

  Future<bool> rejectCourse(int courseId) async {
    try {
      await _client.post('/admin/courses/$courseId/reject', data: {});
      return true;
    } catch (e) {
      print('Error rejecting course: $e');
      return false;
    }
  }

  // --- Verification (KYC) ---
  Future<List<dynamic>> getVerificationRequests() async {
    try {
      final response = await _client.get('/verification/pending');
      if (response is List) {
        return response;
      }
      return [];
    } catch (e) {
      print('Error fetching verification requests: $e');
      return [];
    }
  }

  Future<bool> approveVerification(int id) async {
    try {
      await _client.post('/verification/$id/approve', data: {});
      return true;
    } catch (e) {
      print('Error approving verification: $e');
      return false;
    }
  }

  Future<bool> rejectVerification(int id, String note) async {
    try {
      await _client.post('/verification/$id/reject', data: {'note': note});
      return true;
    } catch (e) {
      print('Error rejecting verification: $e');
      return false;
    }
  }

  // --- System Configuration (Subjects) ---
  Future<List<dynamic>> getSubjects() async {
    try {
      final response = await _client.get('/admin/system/subjects');
      if (response is List) {
        return response;
      }
      return [];
    } catch (e) {
      print('Error fetching subjects: $e');
      return [];
    }
  }

  Future<bool> createSubject(Map<String, dynamic> data) async {
    try {
      await _client.post('/admin/system/subjects', data: data);
      return true;
    } catch (e) {
      print('Error creating subject: $e');
      return false;
    }
  }

  Future<bool> updateSubject(int id, Map<String, dynamic> data) async {
    try {
      await _client.put('/admin/system/subjects/$id', data: data);
      return true;
    } catch (e) {
      print('Error updating subject: $e');
      return false;
    }
  }

  Future<bool> deleteSubject(int id) async {
    try {
      await _client.delete('/admin/system/subjects/$id');
      return true;
    } catch (e) {
      print('Error deleting subject: $e');
      return false;
    }
  }

  // --- Broadcast Notifications ---
  Future<bool> sendBroadcast(Map<String, dynamic> data) async {
    try {
      await _client.post('/admin/notifications/broadcast', data: data);
      return true;
    } catch (e) {
      print('Error sending broadcast: $e');
      return false;
    }
  }
}

