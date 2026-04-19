import 'package:doantotnghiep/core/theme/edu_theme.dart';
import 'package:doantotnghiep/features/booking/data/booking_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class SessionDetailScreen extends ConsumerStatefulWidget {
  final BookingItem booking;
  final bool isReadOnly;

  const SessionDetailScreen({super.key, required this.booking, this.isReadOnly = false});

  @override
  ConsumerState<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  late TextEditingController _topicController;
  late TextEditingController _feedbackController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _topicController = TextEditingController(text: widget.booking.lessonTopic ?? '');
    _feedbackController = TextEditingController(text: widget.booking.tutorFeedback ?? '');
  }

  @override
  void dispose() {
    _topicController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges({bool completed = false}) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(bookingProvider.notifier).updateSessionInfo(
        widget.booking.id,
        lessonTopic: _topicController.text,
        tutorFeedback: _feedbackController.text,
        completed: completed,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật thông tin buổi học')));
        if (completed) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết buổi học'),
        backgroundColor: EduTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.calendar_today, 'Ngày', DateFormat('dd/MM/yyyy').format(widget.booking.date)),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.access_time, 'Thời gian', widget.booking.timeSlot),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.person, widget.isReadOnly ? 'Gia sư' : 'Học viên', widget.isReadOnly ? widget.booking.tutor.name : (widget.booking.student?.name ?? 'Unknown')),
                   const SizedBox(height: 8),
                   _buildInfoRow(Icons.info_outline, 'Trạng thái', widget.booking.status),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text("Nội dung bài học", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            widget.isReadOnly 
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!)
                  ),
                  child: Text(
                    _topicController.text.isNotEmpty ? _topicController.text : 'Chưa có nội dung',
                    style: TextStyle(color: _topicController.text.isNotEmpty ? Colors.black87 : Colors.grey),
                  ),
                )
              : TextField(
                  controller: _topicController,
                  enabled: !widget.isReadOnly,
                  decoration: const InputDecoration(
                    hintText: 'Nhập chủ đề bài học hôm nay...',
                    border: OutlineInputBorder(),
                  ),
                ),
            const SizedBox(height: 16),

            const Text("Nhận xét về học viên", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            widget.isReadOnly 
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!)
                  ),
                  child: Text(
                    _feedbackController.text.isNotEmpty ? _feedbackController.text : 'Chưa có nhận xét',
                    style: TextStyle(color: _feedbackController.text.isNotEmpty ? Colors.black87 : Colors.grey),
                  ),
                )
              : TextField(
                  controller: _feedbackController,
                  enabled: !widget.isReadOnly,
                  decoration: const InputDecoration(
                    hintText: 'Nhận xét tình hình học tập...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
            const SizedBox(height: 32),

            if (!widget.isReadOnly) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _saveChanges(),
                  style: ElevatedButton.styleFrom(backgroundColor: EduTheme.primary, foregroundColor: Colors.white),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Lưu thay đổi'),
                ),
              ),
              
              if (widget.booking.status == 'Upcoming' || widget.booking.status == 'Confirmed') ...[
                 const SizedBox(height: 16),
                 SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => _showCompleteConfirmation(),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                    label: const Text('Hoàn thành buổi học', style: TextStyle(color: Colors.green)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green)),
                  ),
                ),
              ]
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    );
  }

  void _showCompleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hoàn thành'),
        content: const Text('Bạn có chắc chắn muốn đánh dấu buổi học này là đã hoàn thành?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
               Navigator.pop(context);
               _saveChanges(completed: true);
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}
