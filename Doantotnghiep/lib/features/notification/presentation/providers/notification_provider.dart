import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doantotnghiep/core/network/api_client.dart';
import '../../data/notification_repository.dart';
import '../../domain/models/app_notification.dart';
import 'package:doantotnghiep/features/auth/data/auth_repository.dart';
import 'package:doantotnghiep/core/services/notification_service.dart';
import 'package:doantotnghiep/features/chat/data/chat_provider.dart';

/// Notification Repository Provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.read(apiClientProvider));
});

/// Unread notification count provider
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final userAsync = ref.watch(authStateChangesProvider);
  final user = userAsync.value;
  
  if (user == null) return 0;

  // 1. Fetch System Notifications Count
  final systemCount = await ref.read(notificationRepositoryProvider).fetchUnreadCount(user.id);

  // 2. Fetch Chat Count
  final unreadChatAsync = ref.watch(totalUnreadChatCountProvider);
  final chatCount = unreadChatAsync.value ?? 0;

  // Total: System Count + 1 (if there are unread chats)
  return systemCount + (chatCount > 0 ? 1 : 0);
});



/// Notifications List Provider
final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final userAsync = ref.watch(authStateChangesProvider);
  
  final user = userAsync.value;
  if (user == null) return const <AppNotification>[];

  // Fetch API Notifications in parallel (or sequential, simple logic here)
  final notificationsApi = await ref.read(notificationRepositoryProvider).fetchNotifications(user.id);

  // Get Chat Count
  // We use ref.watch to ensure this provider updates when chat count changes
  final unreadChatAsync = ref.watch(totalUnreadChatCountProvider);
  final unreadChat = unreadChatAsync.value ?? 0;

  if (unreadChat > 0) {
      final chatNotif = AppNotification(
         id: 'chat_summary_dyn',
         title: 'Tin nhắn chưa đọc',
         body: 'Bạn có $unreadChat tin nhắn chưa đọc.',
         time: DateTime.now(),
         isRead: false,
         type: 'message',
         data: {'route': '/messages'},
      );
      return [chatNotif, ...notificationsApi];
  }

  return notificationsApi;
});

/// Mark all as read action
final markAllAsReadProvider = Provider((ref) {
  return () async {
    final user = ref.read(authStateChangesProvider).value;
    if (user != null) {
      await ref.read(notificationRepositoryProvider).markAllAsRead(user.id);
      // Invalidate to refresh list
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
    }
  };
});

/// Notification Service Provider
final notificationServiceProvider = Provider((ref) => NotificationService());

/// Initialize Notifications Logic
final initializeNotificationsProvider = FutureProvider((ref) async {
  final service = ref.read(notificationServiceProvider);
  await service.initialize();
  
  // Note: Token sync is now handled by AuthRepository
});
