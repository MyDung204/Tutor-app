/// Schedule Screen
/// 
/// **Purpose:**
/// - Hiển thị lịch học của học viên (sắp tới và lịch sử)
/// - Cho phép học viên xem lịch theo dạng danh sách hoặc lịch (calendar)
/// - Cho phép hủy lịch học và đánh giá gia sư
/// 
/// **Features:**
/// - Tab "Sắp tới": Hiển thị các buổi học sắp diễn ra (status: upcoming, confirmed, pending)
/// - Tab "Lịch sử": Hiển thị các buổi học đã hoàn thành hoặc đã hủy (status: completed, cancelled, finished)
/// - Calendar view: Xem lịch theo dạng lịch (TableCalendar)
/// - List view: Xem lịch theo dạng danh sách
/// - Hủy lịch học: Từ action sheet (menu 3 chấm)
/// - Đánh giá gia sư: Từ lịch sử (chỉ buổi học đã hoàn thành)
/// 
/// **Status Flow:**
/// - Pending → Upcoming → Completed (hoặc Cancelled)
/// - Chỉ có thể hủy lịch ở trạng thái Pending hoặc Upcoming
/// - Chỉ có thể đánh giá ở trạng thái Completed
library;

import 'package:doantotnghiep/features/booking/data/booking_provider.dart';
import 'package:doantotnghiep/features/auth/data/auth_repository.dart';
import 'package:doantotnghiep/features/rating/presentation/review_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:doantotnghiep/features/tutor_dashboard/presentation/session_detail_screen.dart'; // Added

import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

/// Màn hình lịch học của học viên
/// 
/// **Usage:**
/// - Truy cập từ bottom navigation bar → "Lịch học"
/// - Hoặc từ Profile Screen → "Lịch sử buổi học"
/// 
/// **Parameters:**
/// - `initialIndex`: Tab ban đầu (0 = Sắp tới, 1 = Lịch sử)
class ScheduleScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const ScheduleScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isCalendarView = false;
  
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch học'),
        actions: [
          IconButton(
            icon: Icon(_isCalendarView ? Icons.list : Icons.calendar_month),
            tooltip: _isCalendarView ? 'Xem danh sách' : 'Xem lịch',
            onPressed: () {
              setState(() {
                _isCalendarView = !_isCalendarView;
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'Sắp tới'),
            Tab(text: 'Lịch sử'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: _isCalendarView ? const NeverScrollableScrollPhysics() : null, // Disable swipe in calendar mode to avoid conflict
        children: [
          _isCalendarView ? _buildCalendarUpcoming(context) : _buildUpcomingList(context, ref),
          _buildHistoryList(context, ref), // History stays as list for now, or can be calendar too
        ],
      ),
    );
  }

  Widget _buildCalendarUpcoming(BuildContext context) {
     final bookingsAsync = ref.watch(bookingProvider);
     
     return bookingsAsync.when(
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
        data: (allBookings) {
           final upcomingBookings = allBookings.where((b) {
              final status = b.status.toLowerCase();
              return status == 'upcoming' || status == 'confirmed' || status == 'pending';
           }).toList();

           // Group bookings by day for markers
           // Filter list by selected day
           final selectedBookings = upcomingBookings.where((b) {
               return isSameDay(b.date, _selectedDay);
           }).toList();

           return Column(
             children: [
               TableCalendar(
                 firstDay: DateTime.utc(2023, 1, 1),
                 lastDay: DateTime.utc(2030, 12, 31),
                 focusedDay: _focusedDay,
                 calendarFormat: _calendarFormat,
                 selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                 onDaySelected: (selectedDay, focusedDay) {
                   setState(() {
                     _selectedDay = selectedDay;
                     _focusedDay = focusedDay;
                   });
                 },
                 onFormatChanged: (format) {
                   if (_calendarFormat != format) {
                     setState(() {
                       _calendarFormat = format;
                     });
                   }
                 },
                 onPageChanged: (focusedDay) {
                   _focusedDay = focusedDay;
                 },
                 eventLoader: (day) {
                    return upcomingBookings.where((b) => isSameDay(b.date, day)).toList();
                 },
                 calendarStyle: const CalendarStyle(
                   markerDecoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                 ),
               ),
               const Divider(),
               Expanded(
                 child: selectedBookings.isEmpty 
                   ? const Center(child: Text('Không có lịch học ngày này'))
                   : ListView.builder(
                       padding: const EdgeInsets.all(16),
                       itemCount: selectedBookings.length,
                       itemBuilder: (context, index) => _buildBookingCard(context, selectedBookings[index]),
                     ),
               ),
             ],
           );
        },
     );
  }
  
  // Re-factored card builder to be reusable
  Widget _buildBookingCard(BuildContext context, BookingItem booking) {
      final dateStr = DateFormat('dd/MM/yyyy').format(booking.date);
      final isPending = booking.status.toLowerCase() == 'pending' || booking.status == 'Locked';
      
      final user = ref.read(authRepositoryProvider).currentUser;
      final isTutor = user?.role == 'tutor';

      return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                   if ((isTutor || !isPending) && 
                       booking.status.toLowerCase() != 'locked' &&
                       booking.status.toLowerCase() != 'cancelled') {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => SessionDetailScreen(
                         booking: booking,
                         isReadOnly: !isTutor, // Students are read-only
                       )));
                   }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isPending ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1), 
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: Text(
                            isPending ? 'Chờ xác nhận' : 'Sắp diễn ra', 
                            style: TextStyle(
                              color: isPending ? Colors.orange : Colors.blue, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 12
                            )
                          ),
                        ),
                        if (booking.type == 'long_term')
                           Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue[100]!),
                            ),
                            child: const Text(
                              'DÀI HẠN',
                              style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        const Spacer(),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                             _showActionSheet(context, ref, booking.id);
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${booking.tutor.subjects.isNotEmpty ? booking.tutor.subjects.first : "Học"} - ${booking.tutor.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                     if (booking.gradeLevel != null && booking.gradeLevel!.isNotEmpty)
                       Padding(
                         padding: const EdgeInsets.only(bottom: 4.0),
                         child: Text('Lớp: ${booking.gradeLevel}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                       ),
                     Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('$dateStr, ${booking.timeSlot}', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if ((booking.meetingLink != null && booking.meetingLink!.isNotEmpty) || isTutor)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleMeetAction(context, ref, booking, isTutor),
                          icon: const Icon(Icons.video_camera_front),
                          label: Text(
                             isTutor && (booking.meetingLink == null || booking.meetingLink!.isEmpty)
                                ? 'Mở lớp học'
                                : 'Vào lớp học'
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                          ),
                        ),
                      )
                    else 
                       Container(
                         width: double.infinity,
                         padding: const EdgeInsets.symmetric(vertical: 12),
                         alignment: Alignment.center,
                         decoration: BoxDecoration(
                           color: Colors.grey.withOpacity(0.1),
                           borderRadius: BorderRadius.circular(8),
                         ),
                         child: const Text(
                           'Chờ gia sư mở phòng...', 
                           style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)
                         ),
                       ),
                  ],
                ),
              ),
              ),
            );
  }


  Widget _buildUpcomingList(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingProvider);

    return RefreshIndicator(
      onRefresh: () async {
        return ref.refresh(bookingProvider.future);
      },
      child: bookingsAsync.when(
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi tải lịch học: $err')),
        data: (allBookings) {
          final bookings = allBookings.where((b) {
            final status = b.status.toLowerCase();
            return status == 'upcoming' || status == 'confirmed' || status == 'pending' || status == 'locked';
          }).toList();

          if (bookings.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: const Center(child: Text('Chưa có lịch học sắp tới.'))
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return _buildBookingCard(context, bookings[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final user = ref.watch(authRepositoryProvider).currentUser;
    final isTutor = user?.role == 'tutor';

    return bookingsAsync.when(
      skipLoadingOnRefresh: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Lỗi tải lịch sử: $err')),
      data: (allBookings) {
        final historyBookings = allBookings.where((b) {
           final status = b.status.toLowerCase();
           return status == 'completed' || status == 'cancelled' || status == 'finished';
        }).toList();

        if (historyBookings.isEmpty) {
          return const Center(child: Text('Chưa có lịch sử buổi học.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: historyBookings.length,
          itemBuilder: (context, index) {
            final booking = historyBookings[index];
            final dateStr = DateFormat('dd/MM/yyyy').format(booking.date);
            final isCancelled = booking.status.toLowerCase() == 'cancelled';

            return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isCancelled ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1), 
                              borderRadius: BorderRadius.circular(8)
                            ),
                            child: Text(
                                isCancelled ? 'Đã hủy' : 'Đã hoàn thành', 
                                style: TextStyle(
                                  color: isCancelled ? Colors.red : Colors.green, 
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 12
                                )
                            ),
                          ),
                          Text(currencyFormat.format(booking.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${isTutor ? booking.student?.name ?? "Học viên" : booking.tutor.name} - ${booking.tutor.subjects.isNotEmpty ? booking.tutor.subjects.first : "Môn học"}', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                      const SizedBox(height: 4),
                      Text('${booking.timeSlot}, $dateStr', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      if (!isCancelled && !isTutor) // Only allow students to review tutors
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context, 
                                useRootNavigator: true,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                builder: (context) => const ReviewModal()
                              );
                            },
                            icon: const Icon(Icons.star_border),
                            label: const Text('Đánh giá'),
                          ),
                        ),
                    ],
                  ),
                ),
            );
          },
        );
      },
    );
  }

  /// Hiển thị action sheet (menu) cho booking
  /// 
  /// **Purpose:**
  /// - Hiển thị các hành động có thể thực hiện với booking
  /// - Bao gồm: Báo cáo sự cố, Hủy lịch học
  /// 
  /// **Parameters:**
  /// - `context`: BuildContext để hiển thị bottom sheet
  /// - `ref`: WidgetRef để truy cập providers
  /// - `bookingId`: ID của booking cần thao tác
  /// 
  /// **Actions:**
  /// - Báo cáo sự cố: Navigate đến màn hình tạo report
  /// - Hủy lịch học: Xác nhận và gọi API để hủy booking
  void _showActionSheet(BuildContext context, WidgetRef ref, String bookingId) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true, // Fix: Show above BottomNavigationBar
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.report_problem, color: Colors.orange),
                title: const Text('Báo cáo sự cố'),
                onTap: () {
                  context.pop();
                  context.push('/report');
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Hủy lịch học'),
                onTap: () async {
                   context.pop();
                   // Xác nhận trước khi hủy
                   final confirm = await showDialog<bool>(
                     context: context, 
                     builder: (context) => AlertDialog(
                       title: const Text('Xác nhận hủy'),
                       content: const Text('Bạn có chắc chắn muốn hủy buổi học này không?'),
                       actions: [
                         TextButton(
                           onPressed: () => Navigator.pop(context, false),
                           child: const Text('Không'),
                         ),
                         FilledButton(
                           onPressed: () => Navigator.pop(context, true),
                           child: const Text('Có, Hủy'),
                         ),
                       ],
                     ),
                   );

                   // Gọi API để hủy booking
                   if (confirm == true) {
                      await ref.read(bookingProvider.notifier).cancelBooking(bookingId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã hủy lịch học')),
                        );
                        // Refresh booking list
                        ref.invalidate(bookingProvider);
                      }
                   }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleMeetAction(BuildContext context, WidgetRef ref, BookingItem booking, bool isTutor) async {
       String meetingUrl = booking.meetingLink ?? '';
       
       // If Tutor:
       // 1. No link exists -> Auto-create Jitsi
       // 2. Old Google Meet link exists (from previous tests) -> Overwrite with Jitsi
       if (isTutor && (meetingUrl.isEmpty || !meetingUrl.contains('jit.si'))) {
          // Jitsi Meet link format: https://meet.jit.si/{unique_room_name}
          meetingUrl = 'https://meet.jit.si/antigravity-class-${booking.id}'; 
          
          try {
             await ref.read(bookingProvider.notifier).updateSessionInfo(
               booking.id, 
               meetingLink: meetingUrl
             );
             ref.invalidate(bookingProvider);
          } catch (e) {
             if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tạo phòng: $e')));
             }
             return; 
          }
       }

       if (meetingUrl.isEmpty) {
         if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chờ gia sư mở phòng...')));
         }
         return;
       }

       final Uri url = Uri.parse(meetingUrl);
       if (await canLaunchUrl(url)) {
         await launchUrl(url, mode: LaunchMode.externalApplication);
       } else {
         if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể mở cuộc họp')));
         }
       }
  }
}
