import 'package:doantotnghiep/core/theme/edu_theme.dart';
import 'package:doantotnghiep/features/booking/data/booking_provider.dart';
import 'package:doantotnghiep/features/tutor_dashboard/presentation/session_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class _EduTheme {
  static const Color primary = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color background = Color(0xFFF1F5F9);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color rose = Color(0xFFF43F5E);
}

class BookingRequestListScreen extends ConsumerStatefulWidget {
  const BookingRequestListScreen({super.key});

  @override
  ConsumerState<BookingRequestListScreen> createState() => _BookingRequestListScreenState();
}

class _BookingRequestListScreenState extends ConsumerState<BookingRequestListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingProvider);

    return Scaffold(
      backgroundColor: _EduTheme.background,
      appBar: AppBar(
        title: const Text('Quản lý đặt lịch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: _EduTheme.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _EduTheme.primary,
          unselectedLabelColor: _EduTheme.textSecondary,
          indicatorColor: _EduTheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Chờ xử lý'),
            Tab(text: 'Sắp tới'),
            Tab(text: 'Lịch sử'),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: _EduTheme.primary,
        onRefresh: () async {
          return ref.refresh(bookingProvider.future);
        },
        child: bookingsAsync.when(
          data: (bookings) {
            // Filter lists
            final pending = bookings.where((b) => 
              b.status.toLowerCase() == 'locked' || 
              b.status.toLowerCase() == 'pending'
            ).toList();

            final upcoming = bookings.where((b) => 
              b.status.toLowerCase() == 'confirmed' || 
              b.status.toLowerCase() == 'upcoming'
            ).toList();

            final history = bookings.where((b) => 
              b.status.toLowerCase() == 'completed' || 
              b.status.toLowerCase() == 'cancelled' ||
              b.status.toLowerCase() == 'rejected'
            ).toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildBookingList(pending, isPending: true),
                _buildBookingList(upcoming),
                _buildBookingList(history),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Lỗi: $error')),
        ),
      ),
    );
  }

  Widget _buildBookingList(List<BookingItem> bookings, {bool isPending = false}) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.calendar_month_outlined, size: 40, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              'Không có yêu cầu nào',
              style: TextStyle(fontSize: 16, color: _EduTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildBookingItem(bookings[index], isPending: isPending);
      },
    );
  }

  Widget _buildBookingItem(BookingItem booking, {bool isPending = false}) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (booking.status.toLowerCase()) {
      case 'locked':
      case 'pending':
        statusColor = _EduTheme.secondary;
        statusText = 'Chờ xác nhận';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'upcoming':
      case 'confirmed':
        statusColor = _EduTheme.success;
        statusText = 'Sắp tới';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusText = 'Hoàn thành';
        statusIcon = Icons.done_all_rounded;
        break;
      case 'cancelled':
        statusColor = _EduTheme.rose;
        statusText = 'Đã hủy';
        statusIcon = Icons.cancel_rounded;
        break;
      case 'rejected':
        statusColor = Colors.grey;
        statusText = 'Đã từ chối';
        statusIcon = Icons.block_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusText = booking.status;
        statusIcon = Icons.info_outline;
    }

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      decoration: BoxDecoration(
        color: _EduTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Text(
                  currencyFormat.format(booking.totalPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _EduTheme.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade200, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey[100],
                        backgroundImage: booking.student?.avatarUrl != null 
                            ? NetworkImage(booking.student!.avatarUrl!) 
                            : null,
                        child: booking.student?.avatarUrl == null 
                            ? const Icon(Icons.person, color: Colors.grey) 
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.student?.name ?? 'Học viên #${booking.userId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _EduTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.email_outlined, size: 14, color: _EduTheme.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  booking.student?.email ?? 'Chưa cập nhật email',
                                  style: TextStyle(
                                    color: _EduTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),

                // Info Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.calendar_today_rounded,
                        'Ngày học',
                        DateFormat('dd/MM/yyyy').format(booking.date),
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.access_time_rounded,
                        'Thời gian',
                        booking.timeSlot,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                
                if (booking.type == 'long_term') ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: _EduTheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _EduTheme.primary.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.repeat_rounded, size: 16, color: _EduTheme.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Đăng ký khóa học dài hạn',
                          style: TextStyle(
                             color: _EduTheme.primary,
                             fontWeight: FontWeight.w600,
                             fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Start Meeting Button (For Upcoming/Confirmed)
                if (booking.status.toLowerCase() == 'upcoming' || booking.status.toLowerCase() == 'confirmed') ...[
                   const SizedBox(height: 16),
                   SizedBox(
                     width: double.infinity,
                     child: ElevatedButton.icon(
                       onPressed: () => _startMeeting(booking),
                       icon: const Icon(Icons.video_camera_front, size: 16),
                       label: const Text('Vào lớp học'),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.blue,
                         foregroundColor: Colors.white,
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       ),
                     ),
                   ),
                ],
              ],
            ),
          ),

          if (isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectBooking(context, booking),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _EduTheme.rose,
                        side: BorderSide(color: _EduTheme.rose.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Từ chối'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _confirmBooking(context, booking),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _EduTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        shadowColor: _EduTheme.primary.withOpacity(0.4),
                      ),
                      child: const Text('Chấp nhận'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: _EduTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }

  Future<void> _confirmBooking(BuildContext context, BookingItem booking) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      await ref.read(bookingProvider.notifier).confirmBooking(booking.id);
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: const Text('Đã xác nhận buổi học!'),
             backgroundColor: _EduTheme.success,
             behavior: SnackBarBehavior.floating,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
           ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectBooking(BuildContext context, BookingItem booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối yêu cầu?'),
        content: const Text('Bạn chắc chắn muốn từ chối yêu cầu đặt lịch này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Đồng ý', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      await ref.read(bookingProvider.notifier).rejectBooking(booking.id);
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã từ chối yêu cầu'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _startMeeting(BookingItem booking) async {
       String meetingUrl = booking.meetingLink ?? '';
       
       // Force update if empty OR if it's an old Google Meet link
       if (meetingUrl.isEmpty || !meetingUrl.contains('jit.si')) {
          // Auto-create Jitsi link
          meetingUrl = 'https://meet.jit.si/antigravity-class-${booking.id}'; 
          
          try {
             await ref.read(bookingProvider.notifier).updateSessionInfo(
               booking.id, 
               meetingLink: meetingUrl
             );
             ref.invalidate(bookingProvider);
          } catch (e) {
             if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tạo phòng: $e')));
             }
             return; 
          }
       }

       final Uri url = Uri.parse(meetingUrl);
       if (await canLaunchUrl(url)) {
         await launchUrl(url, mode: LaunchMode.externalApplication);
       } else {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể mở cuộc họp')));
         }
       }
  }
}
