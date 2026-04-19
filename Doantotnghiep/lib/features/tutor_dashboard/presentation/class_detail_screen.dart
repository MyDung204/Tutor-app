import 'dart:async';
import 'package:doantotnghiep/features/auth/data/auth_repository.dart';
import 'package:doantotnghiep/features/group/data/course_provider.dart';
import 'package:doantotnghiep/features/group/data/shared_learning_repository.dart';
import 'package:doantotnghiep/features/group/domain/models/course.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:doantotnghiep/features/tutor_dashboard/presentation/widgets/class_announcements_tab.dart';
import 'package:doantotnghiep/features/tutor_dashboard/presentation/widgets/class_assignments_tab.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class _EduTheme {
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color secondary = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color background = Color(0xFFF1F5F9);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color purple = Color(0xFF7C3AED);
  static const Color rose = Color(0xFFF43F5E);
}

class ClassDetailScreen extends ConsumerWidget {
  final Course course;

  const ClassDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    // Fix: Use isTutor from model or compare with tutorUserId if available, fallback to legacy check
    final isTutor = course.isTutor || 
                    (course.tutorUserId != null && user?.id.toString() == course.tutorUserId) ||
                    (user?.role == 'tutor' && user?.id.toString() == course.tutorId);

    final isEnrolled = course.isEnrolled;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    
    // Payment Status Check
    final isPaymentDue = course.paymentStatus == 'due';
    final isGracePeriod = course.paymentStatus == 'grace_period';
    final isOverdue = course.paymentStatus == 'overdue';
    final shouldBlockAccess = isGracePeriod || isOverdue;

    return Scaffold(
      backgroundColor: _EduTheme.background,
      body: DefaultTabController(
        length: 4,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 280, // Expanded height for Hero
                pinned: true,
                backgroundColor: _EduTheme.primary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  if (isTutor) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.white),
                      onPressed: () => context.push('/create-class', extra: course),
                    ),
                    IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.white),
                        onPressed: () => _confirmDelete(context, ref),
                      ),
                  ],
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeroSection(context, currencyFormat),
                ),
                bottom: const TabBar(
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(text: "Tổng quan"),
                    Tab(text: "Bảng tin"),
                    Tab(text: "Bài tập"),
                    Tab(text: "Mọi người"),
                  ],
                ),
              ),
            ];
          },
          body: Column(
            children: [
               if (isEnrolled && (isPaymentDue || isGracePeriod || isOverdue))
                 _buildPaymentBanner(context, ref),
               
               Expanded(
                 child: TabBarView(
                  children: [
                    // 1. Overview Tab (Always Visible)
                    RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(coursesProvider);
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             if (isTutor) _buildStatsGrid(currencyFormat),
                             if (isTutor) const SizedBox(height: 20),
                             _buildInfoCard(),
                             const SizedBox(height: 20),
                             _buildTutorInfoCard(context, ref),
                             const SizedBox(height: 20),
                             _buildDescriptionCard(),
                             const SizedBox(height: 80), // Padding for FAB
                           ],
                        ),
                      ),
                    ),
                    
                    // 2. Announcements Tab
                    shouldBlockAccess && !isTutor
                        ? _buildRestrictedAccessView() 
                        : ClassAnnouncementsTab(course: course, isTutor: isTutor),
                  
                    // 3. Assignments Tab
                    shouldBlockAccess && !isTutor
                        ? _buildRestrictedAccessView()
                        : ClassAssignmentsTab(course: course, isTutor: isTutor),
                  
                    // 4. People Tab
                    SingleChildScrollView(
                       padding: const EdgeInsets.all(20),
                       child: Column(
                        children: [
                          if (course.students.isNotEmpty)
                            _buildStudentsCard(context, ref, isTutor)
                          else 
                            const Center(child: Text("Chưa có học viên nào tham gia")),
                          const SizedBox(height: 80),
                        ],
                       ),
                    ),
                  ],
                               ),
               ),
            ],
          ),
        ),
      ),
      floatingActionButton: shouldBlockAccess && !isTutor 
          ? null 
          : _buildFloatingActions(context, ref, isTutor, isEnrolled, user),
    );
  }

  Widget _buildPaymentBanner(BuildContext context, WidgetRef ref) {
    if (course.paymentStatus == 'overdue') {
      return Container(
        padding: const EdgeInsets.all(12),
        color: Colors.red[100],
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Bạn đã quá hạn thanh toán. Vui lòng liên hệ Admin.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }
    
    if (course.paymentStatus == 'grace_period') {
       return _GracePeriodBanner(
         endTime: course.gracePeriodEndsAt, 
         remainingSeconds: course.graceRemainingSeconds
       );
    }

    // Due
    return Container(
        padding: const EdgeInsets.all(12),
        color: Colors.orange[50],
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Học phí đã đến hạn',
                        style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Vui lòng thanh toán để tiếp tục học.',
                        style: TextStyle(color: Colors.orange[800], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                 TextButton(
                   onPressed: () => _handleRefuseTuition(context, ref),
                   child: const Text('Xin gia hạn (3 ngày)', style: TextStyle(color: Colors.grey)),
                 ),
                 const SizedBox(width: 8),
                 ElevatedButton(
                   onPressed: () {
                     // Navigate to Payment
                     context.push('/wallet'); // Or specific payment flow
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.deepOrange,
                     foregroundColor: Colors.white,
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                     visualDensity: VisualDensity.compact,
                   ),
                   child: const Text('Thanh toán'),
                 ),
              ],
            )
          ],
        ),
      );
  }
  
  Widget _buildRestrictedAccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_clock_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Truy cập bị hạn chế',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Vui lòng thanh toán học phí để mở khóa nội dung này.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRefuseTuition(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xin gia hạn đóng học phí?'),
        content: const Text('Bạn sẽ có thêm 3 ngày để truy cập lớp học trước khi bị hạn chế hoàn toàn. Bạn có chắc chắn muốn gia hạn không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đồng ý')),
        ],
      ),
    );

    if (confirmed == true) {
       // Call API
       final repo = ref.read(sharedLearningRepositoryProvider);
       final result = await repo.refuseTuition(course.id);
       if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gia hạn thành công!')));
          ref.invalidate(coursesProvider);
          // Small delay to allow refresh
          await Future.delayed(const Duration(milliseconds: 500));
       } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Có lỗi xảy ra, vui lòng thử lại.')));
       }
    }
  }

  Widget? _buildFloatingActions(BuildContext context, WidgetRef ref, bool isTutor, bool isEnrolled, user) {
    // Chat bubble for enrolled students and course tutor
    if (isEnrolled || isTutor) {
      if (course.mode == 'Online') {
         return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
             // Meet Button
            FloatingActionButton.small(
              heroTag: 'meet_fab',
              onPressed: () => _handleMeetAction(context, ref, isTutor),
              backgroundColor: _EduTheme.primary,
              child: const Icon(Icons.video_camera_front, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 16),
            // Chat button
            FloatingActionButton.small(
              heroTag: 'chat_fab',
              onPressed: () {
                 if (isEnrolled || isTutor) {
                   context.push('/class-chat', extra: course);
                 }
              },
              backgroundColor: Colors.green,
              child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
            ),
          ],
        );
      }
      
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'chat_fab',
            onPressed: () {
               if (isEnrolled || isTutor) {
                 context.push('/class-chat', extra: course);
               }
            },
            backgroundColor: Colors.green,
            child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
          ),
        ],
      );
    }
    
    // Register button for non-enrolled students
    if (!isTutor && user?.role == 'student' && !isEnrolled) {
      return FloatingActionButton.extended(
        onPressed: () => _confirmJoin(context, ref),
        backgroundColor: _EduTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('Đăng ký ngay'),
      );
    }
    
    return null;
  }

  Widget _buildHeroSection(BuildContext context, NumberFormat currencyFormat) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_EduTheme.primary, _EduTheme.purple],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.school, size: 32, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildBadge(
                              course.status == 'open' ? 'Đang tuyển' : 'Đã đóng',
                              course.status == 'open' ? _EduTheme.success : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            _buildBadge(
                              course.mode,
                              course.mode == 'Online' ? _EduTheme.secondary : Colors.blueAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Học phí',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(course.price),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Học viên',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${course.currentStudentCount}/${course.maxStudents}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatsGrid(NumberFormat currencyFormat) {
    final revenue = course.price * course.students.length;
    final remainingSlots = course.maxStudents - course.students.length;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.monetization_on,
            label: 'Doanh thu',
            value: currencyFormat.format(revenue),
            color: _EduTheme.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.event_seat,
            label: 'Chỗ trống',
            value: '$remainingSlots',
            color: _EduTheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _EduTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: _EduTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: _EduTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _EduTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin chi tiết',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _EduTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildModernInfoRow(
            Icons.calendar_today_rounded,
            'Ngày bắt đầu',
            DateFormat('dd/MM/yyyy').format(course.startDate),
            _EduTheme.primary,
          ),
          const Divider(height: 24),
          _buildModernInfoRow(
            Icons.schedule_rounded,
            'Lịch học',
            course.schedule,
            _EduTheme.secondary,
          ),
          const Divider(height: 24),
          _buildModernInfoRow(
            Icons.location_on_rounded,
            'Địa điểm',
            course.address ?? 'Online',
            _EduTheme.rose,
          ),
          const Divider(height: 24),
          _buildModernInfoRow(
            Icons.book_rounded,
            'Môn học',
            '${course.subject} - ${course.gradeLevel}',
            _EduTheme.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _EduTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: _EduTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _EduTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _EduTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: _EduTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Mô tả',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _EduTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            course.description.isNotEmpty
                ? course.description
                : 'Chưa có mô tả chi tiết.',
            style: TextStyle(
              color: course.description.isNotEmpty
                  ? _EduTheme.textPrimary
                  : _EduTheme.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTutorInfoCard(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _EduTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Thông tin Gia sư',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _EduTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
               const CircleAvatar(
                 radius: 20,
                 backgroundColor: Colors.blue,
                 child: Icon(Icons.person, color: Colors.white),
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                   Row(
                     children: [
                       Text(
                         course.tutorName,
                         style: const TextStyle(
                           fontWeight: FontWeight.bold,
                           fontSize: 16,
                         ),
                       ),
                       const SizedBox(width: 6),
                       const Icon(Icons.verified, color: Colors.blue, size: 16),
                       const SizedBox(width: 4),
                       const Text('Gia sư', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                     ],
                   ),
                   if (course.tutorPhone != null)
                     Text(
                       'SĐT: ${course.tutorPhone}',
                       style: const TextStyle(
                         color: Colors.grey,
                         fontSize: 14,
                       ),
                     ),
                 ],
               ),
             ),
             Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                  onPressed: () {
                     // Check access
                     final isTutor = ref.read(authRepositoryProvider).currentUser?.role == 'tutor';
                     final isGracePeriod = course.paymentStatus == 'grace_period';
                     final isOverdue = course.paymentStatus == 'overdue';
                     
                     if (!isTutor && (isGracePeriod || isOverdue)) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng thanh toán học phí để chat')));
                        return;
                     }
                     context.push('/class-chat', extra: course);
                  },
                 ),
                 if (course.tutorPhone != null)
                   IconButton(
                     icon: const Icon(Icons.phone, color: Colors.green),
                     onPressed: () async {
                        final Uri launchUri = Uri(
                          scheme: 'tel',
                          path: course.tutorPhone,
                        );
                        if (await canLaunchUrl(launchUri)) {
                          await launchUrl(launchUri);
                        }
                     },
                   ),
               ],
             ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsCard(BuildContext context, WidgetRef ref, bool isTutor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _EduTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _EduTheme.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.people_rounded,
                  color: _EduTheme.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Học viên (${course.students.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _EduTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: course.students.length,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final s = course.students[index];
              return InkWell(
                onTap: () => _showStudentDetails(context, s),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: _EduTheme.primary.withOpacity(0.1),
                        child: Text(
                          (s['name'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            color: _EduTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['name'] ?? 'Học viên',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _EduTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Gia nhập: ${_formatDate(s['enrolled_at'])}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _EduTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                         icon: const Icon(Icons.info_outline, color: Colors.grey),
                         onPressed: () => _showStudentDetails(context, s),
                      ),
                      if (isTutor)
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _EduTheme.rose.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_remove_rounded,
                              color: _EduTheme.rose,
                              size: 18,
                            ),
                          ),
                          onPressed: () => _confirmKick(
                            context,
                            ref,
                            s['id'].toString(),
                            s['name'] ?? '',
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.tryParse(dateStr.toString()) ?? DateTime.now();
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return '';
    }
  }

  void _showStudentDetails(BuildContext context, Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
           children: [
             CircleAvatar(child: Text((student['name'] ?? 'U')[0].toUpperCase())),
             const SizedBox(width: 10),
             Expanded(child: Text(student['name'] ?? 'Học viên')),
           ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(Icons.email, 'Email', student['email'] ?? 'Không có'),
            const SizedBox(height: 10),
            _detailRow(Icons.phone, 'SĐT', student['phone_number'] ?? 'Không có'),
            const SizedBox(height: 10),
            _detailRow(Icons.calendar_today, 'Tham gia', _formatDate(student['enrolled_at'])),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

 // End of custom methods, keeping _confirmDelete below unused if duplicated or merged
  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đóng lớp'),
        content: const Text('Bạn có chắc muốn đóng/hủy lớp học này không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              ctx.pop();
              final success = await ref.read(sharedLearningRepositoryProvider).deleteCourse(course.id);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa lớp học thành công')));
                  ref.invalidate(coursesProvider);
                  context.pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi xóa lớp')));
                }
              }
            },
            child: const Text('Đồng ý', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmJoin(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng ký lớp học', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn cần thanh toán học phí để tham gia lớp học này.'),
            const SizedBox(height: 16),
            Text('Học phí: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(course.price)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text('Chọn phương thức thanh toán:', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
          ],
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('Hủy')),
          FilledButton.tonal(
            onPressed: () async {
              ctx.pop();
              _processJoin(context, ref, 'part');
            },
            child: Text('Thanh toán 50% (${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(course.price / 2)})'),
          ),
          FilledButton(
            onPressed: () async {
              ctx.pop();
              _processJoin(context, ref, 'full');
            },
            child: const Text('Thanh toán 100%'),
          ),
        ],
      ),
    );
  }

  Future<void> _processJoin(BuildContext context, WidgetRef ref, String paymentType) async {
    final success = await ref.read(sharedLearningRepositoryProvider).joinCourse(course.id, paymentType: paymentType);
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng ký lớp học thành công!')));
        ref.invalidate(coursesProvider);
        // ref.refresh(courseDetailProvider(course.id)); // If details are cached separately
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng ký thất bại. Vui lòng kiểm tra số dư ví.')));
      }
    }
  }

  void _confirmLeave(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rời lớp học'),
        content: const Text('Bạn có chắc muốn hủy đăng ký lớp học này không?'),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              ctx.pop();
              final success = await ref.read(sharedLearningRepositoryProvider).leaveCourse(course.id);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã rời lớp học')));
                  ref.invalidate(coursesProvider);
                  context.pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi rời lớp')));
                }
              }
            },
            child: const Text('Rời lớp', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }





  void _showSuccessDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            const Text('Đăng ký thành công!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Bạn có thể xem lớp học trong mục "Lớp của tôi".', textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ctx.pop();
              ref.invalidate(coursesProvider);
              context.pop();
            },
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMeetAction(BuildContext context, WidgetRef ref, bool isTutor) async {
     String meetingUrl = course.meetingLink ?? '';
     
     if (isTutor && meetingUrl.isEmpty) {
        // Auto-create Jitsi link
        meetingUrl = 'https://meet.jit.si/antigravity-course-${course.id}'; 
        
        try {
           await ref.read(sharedLearningRepositoryProvider).updateCourse(
             course.id, 
             {'meeting_link': meetingUrl}
           );
           // Invalidate to refresh (optional)
           // ref.invalidate(courseDetailProvider);
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
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Không thể mở cuộc họp')),
         );
       }
     }
  }

  void _confirmKick(BuildContext context, WidgetRef ref, String studentId, String studentName) {
    final sessionsController = TextEditingController();
    final totalController = TextEditingController(text: '10');
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa học viên $studentName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Hành động này sẽ xóa học viên khỏi lớp và hoàn tiền dựa trên số buổi chưa học.'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Lý do xóa (Bắt buộc)',
                  border: OutlineInputBorder(),
                  hintText: 'VD: Vi phạm nội quy lớp học',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: totalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tổng số buổi khóa học',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: sessionsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số buổi đã học',
                  border: OutlineInputBorder(),
                  hintText: 'VD: 2',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _EduTheme.rose),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Vui lòng nhập lý do xóa học viên')),
                 );
                 return;
              }

              final sessions = int.tryParse(sessionsController.text) ?? 0;
              final total = int.tryParse(totalController.text) ?? 10;
              final reason = reasonController.text.trim();
              
              Navigator.pop(ctx);
              
              // Show loading
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang xử lý...')));
              
              final result = await ref.read(sharedLearningRepositoryProvider).kickStudent(
                course.id, 
                studentId, 
                sessions, 
                totalSessions: total,
                reason: reason,
              );
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                _showKickResultValues(context, result ?? 'Đã xóa học viên (Không có chi tiết)');
                ref.invalidate(coursesProvider); // Refresh
              }
            },
            child: const Text('Xác nhận Xóa & Hoàn tiền'),
          ),
        ],
      ),
    );
  }

  void _showKickResultValues(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kết quả xử lý'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }
}

class _GracePeriodBanner extends StatefulWidget {
  final DateTime? endTime;
  final int? remainingSeconds;

  const _GracePeriodBanner({this.endTime, this.remainingSeconds});

  @override
  State<_GracePeriodBanner> createState() => _GracePeriodBannerState();
}

class _GracePeriodBannerState extends State<_GracePeriodBanner> {
  late int _secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.remainingSeconds ?? 
        (widget.endTime != null ? widget.endTime!.difference(DateTime.now()).inSeconds : 0);
    
    if (_secondsLeft > 0) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00:00';
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red[50], // Light red background
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.timer_off_outlined, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Truy cập bị hạn chế (Gia hạn)',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Vui lòng thanh toán trong thời gian còn lại để tránh bị xóa khỏi lớp.',
                      style: TextStyle(color: Colors.red[800], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Còn lại: ${_formatDuration(_secondsLeft)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'monospace',
              ),
            ),
          ),
           const SizedBox(height: 8),
           ElevatedButton(
             onPressed: () {
               context.push('/wallet'); // Or correct path
             },
             style: ElevatedButton.styleFrom(
               backgroundColor: Colors.red[700],
               foregroundColor: Colors.white,
             ),
             child: const Text('Thanh toán ngay'),
           ),
        ],
      ),
    );
  }
}
