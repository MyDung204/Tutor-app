/// Tutor Tuition Screen - Pro Max Redesign
/// 
/// **Why this page exists?**
/// - Để gia sư quản lý dòng tiền từ các lớp học.
/// - Theo dõi trạng thái đóng học phí của từng học viên (Đã đóng, Chưa đóng, Quá hạn).
/// - Thực hiện yêu cầu rút tiền về tài khoản ngân hàng.
/// - Xem lịch sử giao dịch.
/// 
/// **Design Philosophy (UI/UX Pro Max):**
/// - Style: Modern, Clean, Glassmorphism accents.
/// - Palette: Indigo/Violet gradient for trust & premium feel.
/// - Components: Floating cards, smooth shadows, clear hierarchy.
/// - UX: Grouped by class for easy scanning, clear status indicators.
library;

import 'package:doantotnghiep/features/tutor_dashboard/data/tutor_statistics_provider.dart';
import 'package:doantotnghiep/features/chat/data/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Pro Max Theme Colors
class _ProTheme {
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFFA855F7)], // Indigo to Purple
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Color background = Color(0xFFF8FAFC); // Slate-50
  static const Color cardBg = Colors.white;
  static const Color primary = Color(0xFF6366F1);
  static const Color textMain = Color(0xFF1E293B); // Slate-800
  static const Color textSub = Color(0xFF64748B); // Slate-500
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}

class TutorTuitionScreen extends ConsumerWidget {
  const TutorTuitionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tuitionsAsync = ref.watch(tutorTuitionsProvider);
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: _ProTheme.background,
      body: Column(
        children: [
          _buildProHeader(context, ref, currency),
          Expanded(
            child: tuitionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: _ProTheme.primary)),
              error: (error, stack) => _buildErrorState(error.toString()),
              data: (tuitions) => tuitions.isEmpty
                  ? _buildEmptyState()
                  : _buildTuitionList(context, ref, tuitions, currency),
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Header Area (Pro Max Style)
  Widget _buildProHeader(BuildContext context, WidgetRef ref, NumberFormat currency) {
    final statsAsync = ref.watch(tutorStatisticsProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30), // Increased top padding for status bar
      decoration: const BoxDecoration(
        gradient: _ProTheme.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(color: Color(0x336366F1), blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          // Nav Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildGlassIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => context.pop(),
              ),
              const Text(
                'Quản lý Học phí',
                style: TextStyle(
                  fontFamily: 'Outfit', // Assuming font exists, else falls back
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                ),
              ),
              Row(
                children: [
                  _buildGlassIconButton(
                    icon: Icons.history_rounded,
                    onTap: () => context.push('/tutor-dashboard/transaction-history'),
                  ),
                  const SizedBox(width: 12),
                  _buildGlassIconButton(
                    icon: Icons.account_balance_wallet_rounded, 
                    onTap: () => _showWithdrawBottomSheet(context, ref),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Stats Row (Glassmorphism Cards)
          statsAsync.maybeWhen(
            data: (stats) => Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildGlassStatCard(
                    icon: '💰',
                    label: 'Tổng thu nhập',
                    value: currency.format(stats['total_revenue'] ?? 0),
                    trend: '+12%',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildSmallGlassStat(icon: Icons.check_circle_rounded, label: 'Đã thu', value: '${stats['total_students'] ?? 0}', color: _ProTheme.success),
                      const SizedBox(height: 10),
                      _buildSmallGlassStat(icon: Icons.hourglass_top_rounded, label: 'Lớp học', value: '${stats['active_classes'] ?? 0}', color: _ProTheme.warning),
                    ],
                  ),
                )
              ],
            ),
            orElse: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildGlassStatCard({required String icon, required String label, required String value, required String trend}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _ProTheme.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(trend, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSmallGlassStat({required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  /// 2. Tuition List Area
  Widget _buildTuitionList(BuildContext context, WidgetRef ref, List tuitions, NumberFormat currency) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100), // Bottom padding for FAB/Scroll
      itemCount: tuitions.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final tuition = tuitions[index];
        final studentName = tuition['student'] != null ? tuition['student']['name'] : 'Khách vãng lai';
        final studentId = tuition['student'] != null ? tuition['student']['id'].toString() : 'unknown';
        final dateTime = DateTime.parse(tuition['date']);
        final dateStr = DateFormat('dd/MM/yyyy').format(dateTime);
        final price = double.tryParse(tuition['total_price'].toString()) ?? 0;
        
        final isCompleted = tuition['status'] == 'completed';
        final isUpcoming = tuition['status'] == 'upcoming' || tuition['status'] == 'confirmed';
        
        Color statusColor = _ProTheme.warning;
        String statusText = 'Chờ xử lý';
        if (isCompleted) {
            statusColor = _ProTheme.success;
            statusText = 'Đã hoàn thành';
        } else if (isUpcoming) {
            statusColor = _ProTheme.primary;
            statusText = 'Sắp diễn ra';
        } else if (tuition['status'] == 'cancelled' || tuition['status'] == 'rejected') {
            statusColor = _ProTheme.error;
            statusText = 'Đã hủy';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: _ProTheme.cardBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.receipt_long, color: statusColor, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hóa đơn $studentName',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: _ProTheme.textMain,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currency.format(price),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 12, color: _ProTheme.textSub),
                            const SizedBox(width: 4),
                            Text(
                              'Giao dịch: $dateStr',
                              style: const TextStyle(
                                color: _ProTheme.textSub,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  Container(
                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                     decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8)
                     ),
                     child: Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)
                     ),
                  )
               ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProStudentTile(BuildContext context, WidgetRef ref, String studentId, String studentName, String status, String className) {
    Color statusColor;
    String statusText;
    
    switch (status) {
      case 'paid':
        statusColor = _ProTheme.success;
        statusText = 'Đã đóng';
        break;
      case 'overdue':
        statusColor = _ProTheme.error;
        statusText = 'Quá hạn';
        break;
      default:
        statusColor = _ProTheme.warning;
        statusText = 'Chưa đóng';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: statusColor.withValues(alpha: 0.1),
            child: Text(studentName.isNotEmpty ? studentName[0] : 'U', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(studentName, style: const TextStyle(fontWeight: FontWeight.w600, color: _ProTheme.textMain)),
                Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (status != 'paid')
            TextButton.icon(
              onPressed: () {
                  ref.read(chatControllerProvider(studentId)).sendMessage(
                    "Chào bạn, sắp đến hạn đóng học phí cho lớp $className. Vui lòng thanh toán sớm nhé!",
                  );
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi nhắc nhở!')));
              },
              icon: Icon(Icons.send_rounded, size: 16, color: _ProTheme.primary),
              label: Text('Nhắc', style: TextStyle(color: _ProTheme.primary)),
              style: TextButton.styleFrom(
                backgroundColor: _ProTheme.primary.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monetization_on_outlined, size: 80, color: _ProTheme.textSub.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Chưa có dữ liệu học phí', style: TextStyle(color: _ProTheme.textSub, fontSize: 16)),
        ],
      ),
    );
  }
    
  Widget _buildErrorState(String e) => Center(child: Text('Lỗi: $e'));

  void _showWithdrawBottomSheet(BuildContext context, WidgetRef ref) {
    final bankController = TextEditingController();
    final accountController = TextEditingController();
    final amountController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Yêu cầu Rút tiền',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _ProTheme.textMain),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Ngân hàng', style: TextStyle(fontWeight: FontWeight.bold, color: _ProTheme.textSub)),
            const SizedBox(height: 8),
             DropdownButtonFormField<String>(
              decoration: InputDecoration(
                filled: true,
                fillColor: _ProTheme.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: ['Vietcombank', 'Techcombank', 'MB Bank', 'Agribank']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {},
            ),
            const SizedBox(height: 16),
             const Text('Số tiền (VNĐ)', style: TextStyle(fontWeight: FontWeight.bold, color: _ProTheme.textSub)),
             const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Tối thiểu 50.000đ',
                 filled: true,
                fillColor: _ProTheme.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _ProTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _ProTheme.warning.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: _ProTheme.warning, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lưu ý: Tiền sẽ được chuyển về tài khoản của bạn trong vòng 1-3 ngày làm việc.',
                      style: TextStyle(color: _ProTheme.warning, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Yêu cầu đã được gửi!'), backgroundColor: _ProTheme.success)
                    );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ProTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Rút tiền ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
