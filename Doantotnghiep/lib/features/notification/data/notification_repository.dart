import 'package:doantotnghiep/core/network/api_client.dart';
import '../domain/models/app_notification.dart';

// Note: notificationRepositoryProvider is now defined in notification_provider.dart to avoid dependency cycles with ApiClient provider.

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  /// Fetch notifications from API
  Future<List<AppNotification>> fetchNotifications(String userId) async {
    try {
      final response = await _apiClient.get('/notifications?limit=50');
      // API returns paginated: { current_page: 1, data: [...] }
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        final List data = response['data'];
        return data.map((json) => AppNotification.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Fetch Notifications Error: $e');
      return [];
    }
  }

  /// Get unread count from API (approximate or separate endpoint)
  /// For now, we can fetch latest and count, or add an endpoint.
  /// Optimization: Client side count from fetched list, or backend count.
  /// Let's count locally from the list for simplicity, or assume 0 if lazy.
  /// Better: Add /notifications/unread-count endpoint later.
  Future<int> fetchUnreadCount(String userId) async {
    // Hack: fetch list and count. Not efficient but works for small scale.
    try {
      final list = await fetchNotifications(userId);
      return list.where((n) => !n.isRead).length;
    } catch (e) {
      return 0;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    await _apiClient.post('/notifications/$notificationId/read');
  }

  /// Mark all as read
  Future<void> markAllAsRead(String userId) async {
    await _apiClient.post('/notifications/read-all');
  }

  /// Send Test Notification (Debug)
  Future<void> sendTestNotification(String userId) async {
    await _apiClient.post('/send-notification', data: {
      'user_id': userId,
      'title': 'Test Push Up',
      'body': 'Đây là tin nhắn kiểm tra tính năng push up (heads-up)!',
    });
  }
}
