/// My Classes Screen - Redesigned
/// 
/// **Purpose:**
/// - Hiển thị danh sách lớp học của gia sư hoặc học viên
/// - Modern design với EduTheme
library;

import 'package:doantotnghiep/features/group/data/shared_learning_repository.dart';
import 'package:doantotnghiep/features/group/domain/models/course.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:doantotnghiep/features/auth/data/auth_repository.dart';
import 'package:intl/intl.dart';
import 'package:doantotnghiep/features/auth/domain/models/app_user.dart';
import 'package:doantotnghiep/features/booking/data/booking_provider.dart';

/// Education Theme Colors
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
}

final myCoursesProvider = FutureProvider.autoDispose<List<Course>>((ref) async {
  return ref.watch(sharedLearningRepositoryProvider).getMyCourses();
});

class MyClassesScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  
  const MyClassesScreen({
    super.key, 
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MyClassesScreen> createState() => _MyClassesScreenState();
}

class _MyClassesScreenState extends ConsumerState<MyClassesScreen> {
  // No TabController needed anymore

  @override
  Widget build(BuildContext context) {
    // Determine which view to show based on initialIndex
    // 0: Classes (Lớp học)
    // 1: Tutoring (Dạy kèm)
    final isTutoring = widget.initialIndex == 1;
    final title = isTutoring ? 'Học viên dạy kèm' : 'Quản lý lớp học';
    final subtitle = isTutoring ? 'Danh sách học viên' : 'Các lớp học đang giảng dạy';

    return Scaffold(
      backgroundColor: _EduTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, ref, title, subtitle, !isTutoring),
            
            // Content
            Expanded(
              child: isTutoring 
                  ? _buildTutoringTab(context, ref)
                  : _buildClassesTab(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: CLASSES (COURSES) ---
  Widget _buildClassesTab(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(myCoursesProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    
    return RefreshIndicator(
      color: _EduTheme.primary,
      onRefresh: () async {
        return ref.refresh(myCoursesProvider.future);
      },
      child: coursesAsync.when(
        skipLoadingOnRefresh: true,
        data: (courses) {
          if (courses.isEmpty) {
             return _buildEmptyState(context, ref, 'Chưa có lớp học nào', 'Tạo lớp học đầu tiên của bạn');
          }
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              return _buildCourseCard(context, ref, courses[index], currencyFormat);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: _EduTheme.primary)),
        error: (err, stack) => _buildErrorState(err.toString()),
      ),
    );
  }

  // --- TAB 2: TUTORING (BOOKINGS) ---
  Widget _buildTutoringTab(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingProvider);
    final currentUser = ref.watch(authRepositoryProvider).currentUser;

    return RefreshIndicator(
      color: _EduTheme.primary,
      onRefresh: () async {
        ref.invalidate(bookingProvider);
      },
      child: bookingsAsync.when(
        skipLoadingOnRefresh: true,
        data: (bookings) => _buildStudentList(context, ref, bookings),
        loading: () => const Center(child: CircularProgressIndicator(color: _EduTheme.primary)),
        error: (err, stack) {
           final staleData = bookingsAsync.valueOrNull;
           if (staleData != null && staleData.isNotEmpty) {
              return _buildStudentList(context, ref, staleData);
           }
           return _buildErrorState(err.toString());
        },
      ),
    );
  }

  Widget _buildStudentList(BuildContext context, WidgetRef ref, List<BookingItem> bookings) {
      final currentUser = ref.watch(authRepositoryProvider).currentUser;

      if (bookings.isEmpty) {
          return _buildEmptyState(context, ref, 'Chưa có lịch dạy kèm', 'Học viên sẽ đặt lịch với bạn');
      }

      // Filter bookings where I am the tutor
      final myBookings = bookings.where((b) {
          final tutorId = b.tutor.id.toString();
          final myTutorId = currentUser?.tutorProfile?['id']?.toString();
          final myUserId = currentUser?.id.toString();
          return tutorId == myTutorId || tutorId == myUserId;
      }).toList();

      if (myBookings.isEmpty) {
          return _buildEmptyState(context, ref, 'Chưa có lịch dạy kèm', 'Danh sách dạy kèm trống');
      }

      final Map<String, List<BookingItem>> studentGroups = {};
      
      for (var b in myBookings) {
          // Handle missing student object by creating a placeholder from userId
          final studentId = b.student?.id ?? b.userId;
          if (!studentGroups.containsKey(studentId)) studentGroups[studentId] = [];
          studentGroups[studentId]!.add(b);
      }
      
      final students = studentGroups.entries.toList();

      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: students.length,
        itemBuilder: (context, index) {
          final studentId = students[index].key;
          final studentBookings = students[index].value;
          var student = studentBookings.first.student;
          
          // Fallback if student is null
          student ??= AppUser(
            id: studentId, 
            name: 'Student #$studentId', 
            email: '', 
            role: 'student'
          );
          
          // Calculate Progress across ALL bookings for this student (Simplified)
          // Ideally split by "Course/Topic".
          // Let's try to detect "Long Term" series.
          final totalSessions = studentBookings.length;
          final completed = studentBookings.where((b) => b.status.toLowerCase() == 'completed').length;
          final progress = totalSessions > 0 ? completed / totalSessions : 0.0;
          
          // Determine current/next session
          studentBookings.sort((a, b) => a.date.compareTo(b.date));
          
          // FIXED: Handle empty list or no future date
          BookingItem? upcoming;
          try {
             upcoming = studentBookings.firstWhere(
                (b) => b.date.isAfter(DateTime.now()),
             );
          } catch (_) {
             upcoming = studentBookings.isNotEmpty ? studentBookings.last : null;
          }
           
           if (upcoming == null) return const SizedBox.shrink(); // Should not happen

          return _buildStudentCard(context, student, totalSessions, completed, progress, upcoming);
        },
      );
  }

  Widget _buildStudentCard(
    BuildContext context, 
    AppUser student, 
    int total, 
    int completed, 
    double progress, 
    BookingItem nextSession
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _EduTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
             context.push('/student-booking-detail', extra: student);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: student.avatarUrl != null ? NetworkImage(student.avatarUrl!) : null,
                      backgroundColor: _EduTheme.primary.withValues(alpha: 0.1),
                      child: student.avatarUrl == null ? Text(student.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: _EduTheme.primary)) : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _EduTheme.textPrimary),
                          ),
                          Text(
                             nextSession.gradeLevel != null ? 'Lớp: ${nextSession.gradeLevel}' : 'Học viên',
                             style: TextStyle(color: _EduTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Container(
                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                       decoration: BoxDecoration(
                         color: _EduTheme.secondary.withValues(alpha: 0.1),
                         borderRadius: BorderRadius.circular(8),
                       ),
                       child: const Text('Đang dạy', style: TextStyle(color: _EduTheme.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Progress
                Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     const Text('Tiến độ dạy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _EduTheme.textSecondary)),
                     Text('$completed/$total buổi', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _EduTheme.textPrimary)),
                   ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: _EduTheme.background,
                    valueColor: const AlwaysStoppedAnimation<Color>(_EduTheme.success),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Next Session
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _EduTheme.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: _EduTheme.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Buổi tới: ${DateFormat('dd/MM HH:mm').format(nextSession.date)}',
                          style: const TextStyle(fontSize: 13, color: _EduTheme.textPrimary, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 16, color: _EduTheme.textSecondary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Header
  Widget _buildHeader(BuildContext context, WidgetRef ref, String title, String subtitle, [bool showAddButton = true]) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: _EduTheme.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _EduTheme.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _EduTheme.textPrimary),
            ),
          ),

          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _EduTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: _EduTheme.textSecondary),
                ),
              ],
            ),
          ),
          if (showAddButton)
            GestureDetector(
              onTap: () {
                final user = ref.read(authStateChangesProvider).value;
                final isVerified = user?.tutorProfile?['is_verified'] == true;
                if (!isVerified) {
                   showDialog(
                      context: context, 
                      builder: (context) => AlertDialog(
                        title: const Text('Yêu cầu xác thực'),
                        content: const Text('Bạn cần xác thực tài khoản (KYC) để tạo lớp học mới.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
                          FilledButton(onPressed: () => context.push('/settings'), child: const Text('Cài đặt')),
                        ],
                      )
                   );
                   return;
                }
                context.push('/create-class');
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _EduTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded, color: _EduTheme.primary),
              ),
            ),
        ],
      ),
    );
  }

  /// Course Card
  Widget _buildCourseCard(BuildContext context, WidgetRef ref, Course course, NumberFormat currencyFormat) {
    // ... Existing display logic
    // Restored logic
    final progress = course.maxStudents > 0 ? course.students.length / course.maxStudents : 0.0;
    final remainingSlots = course.maxStudents - course.students.length;
    final isPending = course.status == 'pending';
    final isRejected = course.status == 'rejected';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _EduTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('/class-detail', extra: course).then((_) {
              ref.refresh(myCoursesProvider); // Fixed refresh call
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getSubjectColor(course.subject).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _getSubjectIcon(course.subject),
                        color: _getSubjectColor(course.subject),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                               Expanded(child: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: _EduTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                               if (isPending) Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)), child: const Text('Chờ duyệt', style: TextStyle(color: Colors.white, fontSize: 10))),
                               if (isRejected) Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)), child: const Text('Từ chối', style: TextStyle(color: Colors.white, fontSize: 10))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildBadge(course.gradeLevel, _EduTheme.secondary),
                              const SizedBox(width: 8),
                              _buildBadge(course.mode, course.mode == 'Online' ? _EduTheme.success : _EduTheme.primary),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: _EduTheme.textSecondary),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 16, color: _EduTheme.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(child: Text(course.schedule, style: TextStyle(color: _EduTheme.textSecondary, fontSize: 13), overflow: TextOverflow.ellipsis)),
                    Text(currencyFormat.format(course.price), style: const TextStyle(color: _EduTheme.success, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0), backgroundColor: _EduTheme.background, valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? _EduTheme.secondary : _EduTheme.primary), minHeight: 6)),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Icon(Icons.group_rounded, size: 16, color: _EduTheme.textSecondary), const SizedBox(width: 4), Text('${course.students.length}/${course.maxStudents} học viên', style: TextStyle(color: _EduTheme.textSecondary, fontSize: 12))]), Text(remainingSlots > 0 ? 'Còn $remainingSlots slot' : '✅ Đã đầy', style: TextStyle(color: remainingSlots > 0 ? _EduTheme.textSecondary : _EduTheme.success, fontSize: 12, fontWeight: remainingSlots <= 0 ? FontWeight.w600 : FontWeight.normal))]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
    );
  }

  /// Empty State
  Widget _buildEmptyState(BuildContext context, WidgetRef ref, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: _EduTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.school_rounded, size: 56, color: _EduTheme.primary),
          ),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _EduTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: _EduTheme.textSecondary, fontSize: 15)),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  /// Error State
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 56, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text('Có lỗi xảy ra', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _EduTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(error, style: TextStyle(color: _EduTheme.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ... Helpers _getSubjectIcon, _getSubjectColor (Same as before)
  /// Get icon for subject
  IconData _getSubjectIcon(String subject) {
    final subjectLower = subject.toLowerCase();
    if (subjectLower.contains('toán')) return Icons.calculate_rounded;
    if (subjectLower.contains('văn')) return Icons.edit_note_rounded;
    if (subjectLower.contains('anh')) return Icons.translate_rounded;
    if (subjectLower.contains('lý')) return Icons.bolt_rounded;
    if (subjectLower.contains('hóa')) return Icons.science_rounded;
    if (subjectLower.contains('sinh')) return Icons.biotech_rounded;
    if (subjectLower.contains('sử')) return Icons.history_edu_rounded;
    if (subjectLower.contains('địa')) return Icons.public_rounded;
    if (subjectLower.contains('tin')) return Icons.computer_rounded;
    return Icons.auto_stories_rounded;
  }

  /// Get color for subject
  Color _getSubjectColor(String subject) {
    final subjectLower = subject.toLowerCase();
    if (subjectLower.contains('toán')) return const Color(0xFF3B82F6);
    if (subjectLower.contains('văn')) return const Color(0xFFEC4899);
    if (subjectLower.contains('anh')) return const Color(0xFF8B5CF6);
    if (subjectLower.contains('lý')) return const Color(0xFFF59E0B);
    if (subjectLower.contains('hóa')) return const Color(0xFF10B981);
    if (subjectLower.contains('sinh')) return const Color(0xFF14B8A6);
    if (subjectLower.contains('sử')) return const Color(0xFFF97316);
    if (subjectLower.contains('địa')) return const Color(0xFF06B6D4);
    if (subjectLower.contains('tin')) return const Color(0xFF6366F1);
    return _EduTheme.primary;
  }
}
