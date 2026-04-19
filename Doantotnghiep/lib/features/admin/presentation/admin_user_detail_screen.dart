import 'package:doantotnghiep/core/theme/app_theme.dart';
import 'package:doantotnghiep/features/admin/data/admin_user_detail_provider.dart';
import 'package:doantotnghiep/features/admin/data/admin_user_detail_repository.dart';
import 'package:doantotnghiep/features/admin/presentation/widgets/admin_stats_card.dart'; // Reusing for consistency
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  final int userId;

  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(adminUserDetailProvider(widget.userId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Chi tiết người dùng'),
        actions: [
          userAsync.when(
            data: (data) {
              final user = data['user'];
              final isBanned = user['is_banned'] == true;
              return IconButton(
                icon: Icon(isBanned ? Icons.lock_open : Icons.block, color: isBanned ? AppTheme.successColor : AppTheme.errorColor),
                tooltip: isBanned ? 'Mở khóa' : 'Khóa tài khoản',
                onPressed: () => _toggleBan(user),
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          )
        ],
      ),
      body: userAsync.when(
        data: (data) {
          final user = data['user'];
          final wallet = data['wallet'] ?? {'balance': 0, 'currency': 'VND'};
          final stats = data['stats'] ?? {};

          return Column(
            children: [
              _buildHeader(user, theme),
              Container(
                 decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: AppTheme.dividerColor)),
                 ),
                 child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: AppTheme.textSecondary,
                  indicatorColor: AppTheme.primaryColor,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Tổng quan'),
                    Tab(text: 'Tài chính'),
                    Tab(text: 'Rủi ro & Báo cáo'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(user, wallet, stats),
                    _buildFinancialTab(wallet),
                    _buildRiskTab(stats),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> user, ThemeData theme) {
    final isTutor = user['role'] == 'tutor';
    final isBanned = user['is_banned'] == true;
    
    // Fallback avatar logic
    final firstChar = (user['name'] as String? ?? 'U').substring(0, 1).toUpperCase();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: isTutor ? AppTheme.warningColor.withOpacity(0.1) : AppTheme.primaryColor.withOpacity(0.1),
            backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
            child: user['avatar_url'] == null 
                ? Text(firstChar, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isTutor ? AppTheme.warningColor : AppTheme.primaryColor))
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user['name'] ?? 'No Name', 
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    _buildStatusBadge(
                      isTutor ? 'Gia sư' : 'Học viên', 
                      isTutor ? AppTheme.warningColor : AppTheme.primaryColor
                    ),
                    if (isBanned) ...[
                      const SizedBox(width: 8),
                      _buildStatusBadge('Đã Khóa', AppTheme.errorColor),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(user['email'] ?? '', style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Row(
                   children: [
                     Icon(Icons.calendar_today, size: 14, color: AppTheme.textTertiary),
                     const SizedBox(width: 4),
                     Text(
                        'Tham gia: ${user['created_at'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(user['created_at'])) : 'Unknown'}',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
                     ),
                   ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, dynamic> user, Map<String, dynamic> wallet, Map<String, dynamic> stats) {
    final balance = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(double.tryParse(wallet['balance'].toString()) ?? 0);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
               Expanded(
                 child: _buildInfoCard(
                  'Ví tài khoản', 
                  Icons.account_balance_wallet_outlined, 
                  AppTheme.successColor,
                  context,
                  [
                    _buildRow('Số dư:', balance, isBold: true, color: AppTheme.successColor, context: context),
                  ]
                 ),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: _buildInfoCard(
                  'Hoạt động', 
                  Icons.analytics_outlined, 
                  AppTheme.primaryColor,
                  context,
                  [
                    _buildRow('Bookings:', '${stats['booking_count'] ?? 0}', context: context),
                    if (user['role'] == 'tutor') _buildRow('Lớp học:', '${stats['class_count'] ?? 0}', context: context),
                  ]
                 ),
               ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailSection(
            'Thông tin cá nhân', 
            Icons.person_outline,
            [
              _buildDetailItem(Icons.phone_outlined, 'Số điện thoại', user['phone_number'] ?? 'Chưa cập nhật'),
              _buildDetailItem(Icons.location_on_outlined, 'Địa chỉ', user['address'] ?? 'Chưa cập nhật'),
              if (user['bio'] != null) _buildDetailItem(Icons.info_outline, 'Giới thiệu', user['bio']),
            ],
            context
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
             onPressed: () => context.push('/admin/users/${widget.userId}/activities'),
             icon: const Icon(Icons.history),
             label: const Text('Xem lịch sử hoạt động chi tiết'),
             style: ElevatedButton.styleFrom(
               padding: const EdgeInsets.symmetric(vertical: 12),
               backgroundColor: Colors.white,
               foregroundColor: AppTheme.primaryColor,
               elevation: 0,
               side: const BorderSide(color: AppTheme.primaryColor),
             ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailSection(String title, IconData icon, List<Widget> children, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: const [
           BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.textSecondary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFinancialTab(Map<String, dynamic> wallet) {
      final transactions = wallet['transactions'] as List<dynamic>? ?? [];
      final balance = double.tryParse(wallet['balance'].toString()) ?? 0;
      final formattedBalance = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(balance);

      if (transactions.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textTertiary),
              const SizedBox(height: 16),
              const Text("Chưa có giao dịch nào.", style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: transactions.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
             return Container(
               margin: const EdgeInsets.only(bottom: 20),
               padding: const EdgeInsets.all(20),
               decoration: BoxDecoration(
                 gradient: LinearGradient(colors: [AppTheme.primaryColor, AppTheme.primaryDark]),
                 borderRadius: BorderRadius.circular(16),
                 boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text('Tổng số dư ví', style: TextStyle(color: Colors.white70, fontSize: 14)),
                   const SizedBox(height: 8),
                   Text(formattedBalance, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                 ],
               ),
             );
          }
          
          final tx = transactions[index - 1];
          final amount = double.tryParse(tx['amount'].toString()) ?? 0;
          final isPositive = amount >= 0;
          final formattedAmount = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);
          
          return Container(
             margin: const EdgeInsets.only(bottom: 12),
             decoration: BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.circular(12),
               border: Border.all(color: AppTheme.dividerColor),
             ),
             child: ListTile(
               leading: CircleAvatar(
                 backgroundColor: isPositive ? AppTheme.successColor.withOpacity(0.1) : AppTheme.errorColor.withOpacity(0.1),
                 child: Icon(isPositive ? Icons.arrow_downward : Icons.arrow_upward, color: isPositive ? AppTheme.successColor : AppTheme.errorColor),
               ),
               title: Text(tx['type'] ?? 'Transaction', style: const TextStyle(fontWeight: FontWeight.w600)),
               subtitle: Text(tx['created_at'] != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(tx['created_at'])) : '', style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
               trailing: Text(
                 formattedAmount,
                 style: TextStyle(
                   color: isPositive ? AppTheme.successColor : AppTheme.errorColor,
                   fontWeight: FontWeight.bold,
                   fontSize: 16,
                 ),
               ),
             ),
          );
        },
      );
  }

   Widget _buildRiskTab(Map<String, dynamic> stats) {
      final reportCount = stats['report_count'] ?? 0;
      final isHighRisk = reportCount > 0;

      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
             Container(
               padding: const EdgeInsets.all(20),
               decoration: BoxDecoration(
                 color: isHighRisk ? AppTheme.errorColor.withOpacity(0.05) : AppTheme.successColor.withOpacity(0.05),
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: isHighRisk ? AppTheme.errorColor.withOpacity(0.2) : AppTheme.successColor.withOpacity(0.2)),
               ),
               child: Row(
                 children: [
                    Icon(
                      isHighRisk ? Icons.warning_amber_rounded : Icons.verified_user_outlined, 
                      color: isHighRisk ? AppTheme.errorColor : AppTheme.successColor,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHighRisk ? 'Cảnh báo rủi ro' :'Tài khoản an toàn',
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold, 
                              color: isHighRisk ? AppTheme.errorColor : AppTheme.successColor
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Số lượng báo cáo bị tố cáo: $reportCount',
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    )
                 ],
               ),
             ) 
          ],
        ),
      );
  }

  Widget _buildInfoCard(String title, IconData icon, Color color, BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? color, required BuildContext context}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column( // Stack vertically for better space usage in small columns
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            value, 
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500, 
              color: color ?? AppTheme.textPrimary,
              fontSize: 16
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBan(Map<String, dynamic> user) async {
      final isBanned = user['is_banned'] == true;
       // Xác nhận trước khi khóa/mở khóa
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isBanned ? 'Mở khóa tài khoản' : 'Khóa tài khoản'),
          content: Text(
            isBanned
                ? 'Bạn có chắc chắn muốn mở khóa tài khoản của ${user['name']}?'
                : 'Bạn có chắc chắn muốn khóa tài khoản của ${user['name']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => ctx.pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => ctx.pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: isBanned ? AppTheme.successColor : AppTheme.errorColor,
              ),
              child: Text(isBanned ? 'Mở khóa' : 'Khóa'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final success = await ref.read(adminUserDetailRepositoryProvider).toggleBan(user['id']);
        if (mounted) {
           if (success) {
             ref.invalidate(adminUserDetailProvider(widget.userId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cập nhật trạng thái thành công'), backgroundColor: AppTheme.successColor),
              );
           } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thất bại'), backgroundColor: AppTheme.errorColor),
              );
           }
        }
      }
  }
}
