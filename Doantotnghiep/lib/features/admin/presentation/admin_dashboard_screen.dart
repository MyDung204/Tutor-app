/// Admin Dashboard Screen
/// 
/// **Purpose:**
/// - Màn hình tổng quan hệ thống cho admin
/// - Hiển thị các thống kê quan trọng: doanh thu, số người dùng, số gia sư, số yêu cầu chờ duyệt
/// 
/// **Design:**
/// - Uses `AdminStatsCard` for unified look.
/// - Grid Layout for responsiveness.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doantotnghiep/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:doantotnghiep/features/admin/data/admin_dashboard_provider.dart';
import 'package:doantotnghiep/features/admin/presentation/widgets/admin_stats_card.dart'; // Import Stats Card
import 'package:doantotnghiep/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);
    final theme = Theme.of(context);

    // Helper to get formatted currency
    String formatCurrency(dynamic value) {
      if (value == null) return '0 đ';
      final currencyFormat = NumberFormat.compactCurrency(locale: 'vi_VN', symbol: 'đ');
      final numValue = value is num ? value : double.tryParse(value.toString()) ?? 0;
      return currencyFormat.format(numValue);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản trị hệ thống'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminDashboardStatsProvider),
            tooltip: 'Làm mới',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authViewModelProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) {
          final revenue = formatCurrency(stats['total_revenue']);
          final users = stats['total_users']?.toString() ?? '0';
          final tutors = stats['total_tutors']?.toString() ?? '0';
          final pending = stats['pending_tutors']?.toString() ?? '0';
          final activities = stats['activities'] as List<dynamic>? ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng quan',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold, 
                    color: AppTheme.textPrimary
                  ),
                ),
                const SizedBox(height: 16),
                
                // Stats Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isWide ? 4 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.3,
                      children: [
                        AdminStatsCard(
                          label: 'Tổng doanh thu',
                          value: revenue,
                          icon: Icons.attach_money,
                          color: AppTheme.primaryColor,
                          trend: '+12%', // Placholder for trend
                        ),
                        AdminStatsCard(
                          label: 'Người dùng',
                          value: users,
                          icon: Icons.people,
                          color: AppTheme.successColor,
                          trend: '+5%',
                        ),
                        AdminStatsCard(
                          label: 'Gia sư',
                          value: tutors,
                          icon: Icons.school,
                          color: AppTheme.warningColor,
                        ),
                        AdminStatsCard(
                          label: 'Chờ duyệt',
                          value: pending,
                          icon: Icons.verified_user,
                          color: AppTheme.errorColor, // Highlight pending action
                          onTap: () => context.push('/admin/approve'),
                          trend: pending != '0' ? 'Cần xử lý' : null,
                          isTrendPositive: false,
                        ),
                      ],
                    );
                  }
                ),

                const SizedBox(height: 32),
                Text(
                  'Truy cập nhanh',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                // Quick Actions
                GridView.extent(
                  maxCrossAxisExtent: 110,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.0,
                  children: [
                    _buildQuickAction(context, 'Cấu hình', Icons.settings, Colors.blueGrey, '/admin/system-settings'),
                    _buildQuickAction(context, 'Thông báo', Icons.campaign, Colors.deepOrange, '/admin/broadcast'),
                    _buildQuickAction(context, 'Người dùng', Icons.people_outline, Colors.blue, '/admin/users'),
                    _buildQuickAction(context, 'Duyệt Gia sư', Icons.person_add_outlined, Colors.orange, '/admin/approve'),
                    _buildQuickAction(context, 'Duyệt Khóa', Icons.class_outlined, Colors.purple, '/admin/courses-approve'),
                    _buildQuickAction(context, 'Báo cáo', Icons.flag_outlined, Colors.red, '/admin/reports'),
                    _buildQuickAction(context, 'AI Audit', Icons.security, Colors.teal, '/admin/ai-audit'),
                    _buildQuickAction(context, 'Duyệt KYC', Icons.verified_user_outlined, Colors.green, '/admin/verification'),
                    _buildQuickAction(context, 'Logs', Icons.history, Colors.blueGrey, '/admin/logs'),
                    _buildQuickAction(context, 'Bản đồ', Icons.map, Colors.pink, '/admin/market-map'),
                  ],
                ),

                const SizedBox(height: 32),
                Text(
                  'Hoạt động gần đây',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildActivityList(context, activities),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi tải dữ liệu: $err')),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String title, IconData icon, Color color, String route) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.dividerColor),
      ),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList(BuildContext context, List<dynamic> activities) {
    if (activities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.history, size: 48, color: AppTheme.textTertiary),
              const SizedBox(height: 8),
              Text(
                "Chưa có hoạt động nào.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final act = activities[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: const Icon(Icons.notifications_outlined, color: AppTheme.primaryColor, size: 20),
            ),
            title: Text(
              act['title'] ?? 'Thông báo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              act['body'] ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              act['time_ago'] ?? '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      },
    );
  }
}
