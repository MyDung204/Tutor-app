import 'package:doantotnghiep/features/notification/presentation/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:doantotnghiep/features/auth/data/auth_repository.dart';
import 'package:doantotnghiep/core/theme/edu_theme.dart';
class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final user = ref.watch(authRepositoryProvider).currentUser;
    final isTutor = user?.role == 'tutor' || user?.tutorProfile != null; // fallback check

    return Scaffold(
      appBar: isTutor ? _buildTutorAppBar(context, ref) : _buildStudentAppBar(context, ref),
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate provider to refresh data
           ref.invalidate(notificationsProvider);
        },
        child: notificationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Lỗi: $err')),
          data: (notifications) {
            if (notifications.isEmpty) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Text('Bạn chưa có thông báo nào', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.isRead ? Colors.grey[200] : Colors.blue[50],
                    child: Icon(
                      _getIconForType(item.type),
                      color: item.isRead ? Colors.grey : Colors.blue,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        style: TextStyle(
                          color: item.isRead ? Colors.black54 : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatTime(item.time),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  tileColor: item.isRead ? Colors.transparent : Colors.blue.withValues(alpha: 0.02),
                  onTap: () {
                    if (item.data != null && item.data!.containsKey('route')) {
                       context.push(item.data!['route']);
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'booking':
        return Icons.calendar_today;
      case 'message':
        return Icons.message;
      case 'reminder':
        return Icons.alarm;
      case 'promotion':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy').format(time);
    }
  }

  PreferredSizeWidget _buildStudentAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: const Text('Thông báo'),
      actions: [
        IconButton(
          icon: const Icon(Icons.done_all),
          tooltip: 'Đánh dấu đã đọc tất cả',
          onPressed: () {
            ref.read(markAllAsReadProvider)();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã đánh dấu tất cả là đã đọc')),
            );
          },
        ),
      ],
    );
  }

  PreferredSizeWidget _buildTutorAppBar(BuildContext context, WidgetRef ref) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFFA855F7)], // Indigo to Purple (Pro Theme)
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Thông báo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.done_all, color: Colors.white),
              tooltip: 'Đánh dấu đã đọc tất cả',
              onPressed: () {
                ref.read(markAllAsReadProvider)();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã đánh dấu tất cả là đã đọc')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
