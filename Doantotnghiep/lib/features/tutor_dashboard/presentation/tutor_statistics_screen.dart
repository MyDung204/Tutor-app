import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doantotnghiep/core/theme/edu_theme.dart';
import 'package:doantotnghiep/features/tutor_dashboard/data/tutor_statistics_provider.dart';
import 'package:intl/intl.dart';

class TutorStatisticsScreen extends ConsumerWidget {
  const TutorStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    final statsAsync = ref.watch(tutorStatisticsProvider);
    
    return Scaffold(
      backgroundColor: EduTheme.background,
      appBar: AppBar(
        title: const Text('Thống kê & Thu nhập'),
        centerTitle: true,
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Lỗi: $error')),
        data: (stats) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Revenue Card
                _buildRevenueCard(currency, stats),
                const SizedBox(height: 24),

                // Tabs/Charts Section
                const Text(
                  'Hiệu suất giảng dạy',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildPerformanceGrid(stats),
                const SizedBox(height: 24),

                // Student Distribution
                const Text(
                  'Phân bổ học viên',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildStudentDistribution(),
                const SizedBox(height: 24),

                // Rating History
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Lịch sử đánh giá',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(onPressed: () {}, child: const Text('Xem tất cả')),
                  ],
                ),
                _buildRatingList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRevenueCard(NumberFormat currency, Map<String, dynamic> stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [EduTheme.primary, EduTheme.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: EduTheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng thu nhập quyết toán',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            currency.format(stats['total_revenue'] ?? 0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
               _buildMiniStat('Lớp học', '${stats['active_classes'] ?? 0}', Icons.school),
               const SizedBox(width: 24),
               _buildMiniStat('Đánh giá', '${stats['rating'] ?? 0} ⭐ (${stats['review_count'] ?? 0})', Icons.star),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceGrid(Map<String, dynamic> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildPerformanceCard('Tỉ lệ hoàn thành', '${stats['completion_rate'] ?? 0}%', Icons.check_circle, Colors.green),
        _buildPerformanceCard('Tỉ lệ phản hồi', '${stats['response_time'] ?? 'N/A'}', Icons.bolt, Colors.orange),
        _buildPerformanceCard('Tổng học viên', '${stats['total_students'] ?? 0}', Icons.person, Colors.blue),
        _buildPerformanceCard('Giờ đã dạy', '${stats['teaching_hours'] ?? 0}h', Icons.calendar_today, Colors.purple),
      ],
    );
  }

  Widget _buildPerformanceCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStudentDistribution() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildDistRow('Toán học', 0.6, Colors.blue),
          const SizedBox(height: 12),
          _buildDistRow('Tiếng Anh', 0.3, Colors.purple),
          const SizedBox(height: 12),
          _buildDistRow('Khác', 0.1, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildDistRow(String label, double val, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text('${(val * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: val,
          backgroundColor: color.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation(color),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildRatingList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const CircleAvatar(backgroundColor: EduTheme.primary, child: Icon(Icons.person, color: Colors.white)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Trần Văn B', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (i) => Icon(Icons.star, size: 14, color: i < 5 ? Colors.amber : Colors.grey)),
                    ),
                  ],
                ),
              ),
              Text('2 ngày trước', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            ],
          ),
        );
      },
    );
  }
}
