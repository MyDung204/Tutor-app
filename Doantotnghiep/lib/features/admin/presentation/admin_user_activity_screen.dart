import 'package:doantotnghiep/features/admin/data/admin_user_detail_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final adminUserActivityProvider = FutureProvider.family<List<dynamic>, int>((ref, userId) async {
  return ref.read(adminUserDetailRepositoryProvider).getUserActivities(userId);
});

class AdminUserActivityScreen extends ConsumerWidget {
  final int userId;

  const AdminUserActivityScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(adminUserActivityProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử hoạt động'),
      ),
      body: activityAsync.when(
        data: (activities) {
          if (activities.isEmpty) {
            return const Center(child: Text('Chưa có hoạt động nào được ghi nhận.'));
          }

          return ListView.builder(
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              final type = activity['type'];
              final title = activity['title'] ?? '';
              final description = activity['description'] ?? '';
              final time = activity['created_at'] != null 
                  ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(activity['created_at'])) 
                  : '';

              IconData icon;
              Color color;

              switch (type) {
                case 'booking':
                  icon = Icons.calendar_today;
                  color = Colors.blue;
                  break;
                case 'transaction':
                  icon = Icons.account_balance_wallet;
                  color = Colors.green;
                  break;
                case 'report':
                  icon = Icons.warning;
                  color = Colors.orange;
                  break;
                default:
                  icon = Icons.history;
                  color = Colors.grey;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 1,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.1),
                    child: Icon(icon, color: color),
                  ),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('$description\n$time'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }
}
