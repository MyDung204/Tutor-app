import 'package:doantotnghiep/core/theme/edu_theme.dart';
import 'package:doantotnghiep/features/booking/data/booking_provider.dart';
import 'package:doantotnghiep/features/tutor/domain/models/tutor.dart'; // Added import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class BookingRequestBubble extends ConsumerWidget {
  final int bookingId;
  final bool isUser; // isUser means the viewer is the sender. For tutor, isUser=false if student sent it.

  const BookingRequestBubble({super.key, required this.bookingId, required this.isUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch individual booking query? Or use provider list?
    // Since we only have ID, we might need a Single Booking Provider.
    // However, for now, let's assume we can fetch it or it's in the main list.
    // Better: Creating a specialized future provider for single booking fetch would be safer
    // But for speed, let's check the bookingProvider list cache first.
    
    final bookingListAsync = ref.watch(bookingProvider);
    
    return bookingListAsync.when(
      data: (bookings) {
        // Find the booking
        final booking = bookings.firstWhere(
           (b) => b.id == bookingId.toString(), 
           orElse: () => BookingItem(
              id: '0', 
              userId: '0', 
              tutor: Tutor(id: '0', name: '', avatarUrl: '', rating: 0, reviewCount: 0, hourlyRate: 0, subjects: [], bio: '', location: '', gender: '', teachingMode: [], address: '', weeklySchedule: {}, userId: '0'),
              date: DateTime.now(), 
              timeSlot: '', 
              totalPrice: 0,
            ) 
        );

        if (booking.id == '0') {
           // If not in list (maybe new or cleaned up), we might need to fetch fresh.
           // For now, show loading or simple view
           return Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
             child: const Text("Đang tải thông tin đặt lịch..."),
           );
        }

        return _buildCard(context, ref, booking);
      },
      loading: () => Container(padding: const EdgeInsets.all(8), child: const CircularProgressIndicator()),
      error: (err, stack) => Text('Error loading booking: $err'),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, BookingItem booking) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final isTutor = !isUser; // If I see a message sent by "Partner" (Student), I am Tutor.
    // Wait, `isUser` in ChatMessage means "Current User sent this". 
    // Student sends request -> Student sees `isUser=true`. Tutor sees `isUser=false`.
    // So if `!isUser` (Partner sent this), and Partner is Student, then I am Tutor. 
    // BUT, the context of "Who am I" depends on `ref.read(authRepositoryProvider).currentUser`.
    // Let's rely on `isUser` logic passed from ChatScreen. 
    // If `isUser` is true, I (Student) sent it. 
    // If `isUser` is false, Partner (Student) sent it, so I am Tutor.

    final width = MediaQuery.of(context).size.width * 0.75;

    Color statusColor;
    String statusText;
    switch (booking.status.toLowerCase()) {
      case 'pending': 
        statusColor = Colors.orange; statusText = 'Chờ xác nhận'; break;
      case 'confirmed': 
      case 'upcoming':
        statusColor = Colors.green; statusText = 'Đã chấp nhận'; break;
      case 'cancelled': 
      case 'rejected':
        statusColor = Colors.red; statusText = 'Đã từ chối'; break;
      default: statusColor = Colors.grey; statusText = booking.status;
    }

    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
               color: EduTheme.primary.withOpacity(0.1),
               borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.class_outlined, color: EduTheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(booking.type == 'long_term' ? 'Đề nghị học dài hạn' : 'Đề nghị học thử/lẻ', style: const TextStyle(fontWeight: FontWeight.bold, color: EduTheme.primary))),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
               children: [
                 _buildRow(Icons.calendar_today, DateFormat('dd/MM/yyyy').format(booking.date)),
                 const SizedBox(height: 8),
                 _buildRow(Icons.access_time, booking.timeSlot),
                 const SizedBox(height: 8),
                 _buildRow(Icons.monetization_on_outlined, currencyFormat.format(booking.totalPrice)),
                 const SizedBox(height: 16),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                   decoration: BoxDecoration(
                     color: statusColor.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(20),
                   ),
                   child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                 ),
               ],
            ),
          ),
          
          if (!isUser && booking.status == 'pending')
             Padding(
               padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
               child: Row(
                 children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleAction(context, ref, booking.id, 'reject'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                        child: const Text('Từ chối'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleAction(context, ref, booking.id, 'confirm'),
                         style: ElevatedButton.styleFrom(backgroundColor: EduTheme.primary, foregroundColor: Colors.white),
                        child: const Text('Đồng ý'),
                      ),
                    )
                 ],
               ),
             ),
             
          if (!isUser && booking.status == 'pending')
            Padding(
               padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
               child: SizedBox(
                   width: double.infinity,
                   child: TextButton.icon(
                      onPressed: () {
                          // TODO: Implement Proposal Edit
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng Đề xuất lại đang phát triển')));
                      },
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Đề xuất thay đổi'),
                   ),
               ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, String id, String action) async {
     try {
       if (action == 'confirm') {
          await ref.read(bookingProvider.notifier).confirmBooking(id);
       } else {
          await ref.read(bookingProvider.notifier).rejectBooking(id);
       }
       // Since this is a widget, we rely on provider update to refresh UI
     } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
     }
  }
}
