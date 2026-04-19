import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:doantotnghiep/features/auth/domain/models/app_user.dart';
import 'package:doantotnghiep/features/booking/data/booking_provider.dart';

class _EduTheme {
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color secondary = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color background = Color(0xFFF1F5F9);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
}

class StudentBookingDetailScreen extends ConsumerWidget {
  final AppUser student;
  
  const StudentBookingDetailScreen({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We re-fetch bookings here to ensure we have the latest status
    // and to simplify logic (filtering again)
    final bookingsAsync = ref.watch(bookingProvider);
    
    return Scaffold(
      backgroundColor: _EduTheme.background,
      appBar: AppBar(
        title: const Text('Chi tiết dạy kèm', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: _EduTheme.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          // Filter bookings for this student AND this tutor (implicitly handled by provider mostly, but safe to check)
          // Actually provider returns ALL bookings. We need to filter for this student.
          final studentBookings = bookings.where((b) => b.student?.id == student.id).toList();
          
          if (studentBookings.isEmpty) {
            return const Center(child: Text('Không tìm thấy lịch học'));
          }

          // Sort by date descending
          studentBookings.sort((a, b) => b.date.compareTo(a.date));

          // Calculate stats
          final total = studentBookings.length;
          final completed = studentBookings.where((b) => b.status.toLowerCase() == 'completed').length;
          final cancelled = studentBookings.where((b) => b.status.toLowerCase() == 'cancelled').length;
          final upcoming = total - completed - cancelled;
          
          // Progress
          final progress = total > 0 ? completed / total : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student Profile Card
                _buildStudentProfileCard(context, total, completed, progress),
                
                const SizedBox(height: 24),
                const Text(
                  'Lịch sử buổi học',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _EduTheme.textPrimary),
                ),
                const SizedBox(height: 16),
                
                // Booking List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: studentBookings.length,
                  itemBuilder: (context, index) {
                    return _buildBookingItem(context, ref, studentBookings[index]);
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }

  Widget _buildStudentProfileCard(BuildContext context, int total, int completed, double progress) {
    return Container(
      decoration: BoxDecoration(
        color: _EduTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
             color: Colors.black.withValues(alpha: 0.05),
             blurRadius: 10,
             offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
           Row(
             children: [
               CircleAvatar(
                 radius: 30,
                 backgroundImage: student.avatarUrl != null ? NetworkImage(student.avatarUrl!) : null,
                 backgroundColor: _EduTheme.primary.withValues(alpha: 0.1),
                 child: student.avatarUrl == null ? Text(student.name[0], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _EduTheme.primary)) : null,
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       student.name,
                       style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _EduTheme.textPrimary),
                     ),
                     const SizedBox(height: 4),
                     Text(
                       student.email,
                       style: const TextStyle(fontSize: 14, color: _EduTheme.textSecondary),
                     ),
                   ],
                 ),
               ),
               // Call/Chat buttons could go here
             ],
           ),
           const Divider(height: 32),
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceAround,
             children: [
               _buildStatItem('Tổng buổi', '$total'),
               _buildStatItem('Hoàn thành', '$completed', color: _EduTheme.success),
               _buildStatItem('Còn lại', '${total - completed}', color: _EduTheme.secondary),
             ],
           ),
           const SizedBox(height: 20),
           ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: _EduTheme.background,
              valueColor: const AlwaysStoppedAnimation<Color>(_EduTheme.success),
              minHeight: 8,
            ),
           ),
           const SizedBox(height: 8),
           Align(
             alignment: Alignment.centerRight,
             child: Text('${(progress * 100).toInt()}% Hoàn thành', style: const TextStyle(fontSize: 12, color: _EduTheme.textSecondary)),
           ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color ?? _EduTheme.textPrimary)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: _EduTheme.textSecondary)),
      ],
    );
  }

  Widget _buildBookingItem(BuildContext context, WidgetRef ref, BookingItem booking) {
    final statusColor = _getStatusColor(booking.status);
    final statusText = _getStatusText(booking.status);
    final isUpcoming = booking.status.toLowerCase() == 'confirmed' || booking.status.toLowerCase() == 'pending'; // Adjust based on exact status strings
    // Can action if: Status is confirmed AND date is today/past
    // Or if we want to allow marking complete manually? Yes.
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _EduTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.class_outlined, color: statusColor, size: 24),
          ),
          title: Text(
            DateFormat('dd/MM/yyyy - HH:mm').format(booking.date),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                     decoration: BoxDecoration(
                       color: statusColor.withValues(alpha: 0.1),
                       borderRadius: BorderRadius.circular(4),
                     ),
                     child: Text(statusText, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                   ),
                   const SizedBox(width: 8),
                   if (booking.gradeLevel != null)
                   Text(booking.gradeLevel!, style: const TextStyle(fontSize: 12, color: _EduTheme.textSecondary)),
                ],
              ),
            ],
          ),
          children: [
             Padding(
               padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Divider(),
                   if (booking.meetingLink != null)
                     ListTile(
                       contentPadding: EdgeInsets.zero,
                       leading: const Icon(Icons.link, color: Colors.blue),
                       title: const Text('Link học', style: TextStyle(fontSize: 14)),
                       subtitle: Text(booking.meetingLink!, style: const TextStyle(color: Colors.blue)),
                       onTap: () {
                         // Launch URL logic
                       },
                     ),
                    
                   if (booking.tutorFeedback != null) ...[
                      const Text('Đánh giá của bạn:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(booking.tutorFeedback!, style: const TextStyle(color: _EduTheme.textSecondary, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 12),
                   ],

                   // Actions
                   if (isUpcoming) 
                   Row(
                     mainAxisAlignment: MainAxisAlignment.end,
                     children: [
                       TextButton(
                         onPressed: () {
                           // Cancel Logic
                         },
                         child: const Text('Hủy', style: TextStyle(color: Colors.red)),
                       ),
                       const SizedBox(width: 8),
                       ElevatedButton(
                         onPressed: () {
                            _showUpdateSessionDialog(context, ref, booking);
                         },
                         style: ElevatedButton.styleFrom(
                           backgroundColor: _EduTheme.primary,
                           foregroundColor: Colors.white,
                         ),
                         child: const Text('Cập nhật'),
                       ),
                     ],
                   ),
                 ],
               ),
             ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return _EduTheme.primary;
      case 'completed': return _EduTheme.success;
      case 'cancelled': return _EduTheme.error;
      case 'pending': return _EduTheme.secondary;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return 'Sắp tới';
      case 'completed': return 'Hoàn thành';
      case 'cancelled': return 'Đã hủy';
      case 'pending': return 'Chờ xác nhận';
      default: return status;
    }
  }

  void _showUpdateSessionDialog(BuildContext context, WidgetRef ref, BookingItem booking) {
    final linkController = TextEditingController(text: booking.meetingLink);
    final noteController = TextEditingController(text: booking.tutorFeedback);
    bool markCompleted = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Cập nhật buổi học'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: linkController,
                decoration: const InputDecoration(
                  labelText: 'Link phòng học (Google Meet/Zoom)',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú / Đánh giá',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                 title: const Text('Đánh dấu đã hoàn thành'),
                 value: markCompleted,
                 onChanged: (val) => setState(() => markCompleted = val!),
                 contentPadding: EdgeInsets.zero,
                 activeColor: _EduTheme.success,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                 // Call Update API
                 Navigator.pop(ctx);
                 
                 final notifier = ref.read(bookingProvider.notifier);
                 // Assuming updateSessionInfo exists in BookingNotifier or we call Repo directly.
                 // Ideally we should create a method in BookingNotifier.
                 // For now, let's assume we implement it there.
                 
                 await notifier.updateSessionInfo(
                   booking.id, 
                   meetingLink: linkController.text,
                   tutorFeedback: noteController.text,
                   completed: markCompleted
                 );
              }, 
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}
