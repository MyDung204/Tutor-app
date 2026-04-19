import 'package:flutter/material.dart';
import 'package:doantotnghiep/features/tutor_dashboard/domain/models/tutor_request.dart';
import 'package:doantotnghiep/features/tutor_dashboard/data/tutor_request_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MyRequestDetailScreen extends ConsumerWidget {
  final TutorRequest request;

  const MyRequestDetailScreen({super.key, required this.request});

  Future<void> _deleteRequest(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa yêu cầu?'),
        content: const Text('Bạn có chắc chắn muốn xóa bài đăng này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Mock Delete via Provider (Memory only)
      ref.read(tutorRequestsProvider.notifier).removeRequest(request.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa yêu cầu.')));
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết yêu cầu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () {
               context.push('/create-tutor-request', extra: request).then((_) {
                 // May need to refresh provider if updated
               });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _deleteRequest(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Khi gia sư quan tâm, họ sẽ gửi tin nhắn cho bạn. Vui lòng kiểm tra mục "Tin nhắn".',
                      style: TextStyle(color: Colors.blue, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/messages'), 
                    child: const Text('Hộp thư'),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Môn học & Lớp'),
            Text('${request.subject} - ${request.gradeLevel}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            
            const SizedBox(height: 20),
            _buildSectionTitle('Ngân sách dự kiến'),
            Text(
              '${currencyFormat.format(request.minBudget)} - ${currencyFormat.format(request.maxBudget)} / buổi',
              style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),
            _buildSectionTitle('Thời gian học'),
            Text(request.schedule, style: const TextStyle(fontSize: 16)),

            const SizedBox(height: 20),
            _buildSectionTitle('Địa điểm / Hình thức'),
            Text(request.location, style: const TextStyle(fontSize: 16)),

            const SizedBox(height: 20),
            _buildSectionTitle('Yêu cầu chi tiết'),
            Text(request.description.isEmpty ? 'Không có mô tả thêm' : request.description, style: const TextStyle(fontSize: 16, height: 1.5)),

            const SizedBox(height: 30),
            Center(
              child: Text(
                'Đăng ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(request.createdAt)}',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
    );
  }
}
