import 'package:doantotnghiep/features/group/data/shared_learning_repository.dart';
import 'package:doantotnghiep/features/group/domain/models/course.dart';
import 'package:doantotnghiep/core/theme/edu_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// Reuse provider or create specific one if needed. reusing myCoursesProvider from tutor is fine if repo handles role.
final myEnrolledCoursesProvider = FutureProvider.autoDispose<List<Course>>((ref) async {
  return ref.watch(sharedLearningRepositoryProvider).getMyCourses();
});

class MyEnrolledClassesScreen extends ConsumerWidget {
  const MyEnrolledClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(myEnrolledCoursesProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: EduTheme.background,
      appBar: AppBar(
        title: const Text('Lớp học của tôi'),
        elevation: 0,
      ),
      body: coursesAsync.when(
        data: (courses) {
          if (courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.class_outlined, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Bạn chưa tham gia lớp học nào', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/search?subject='), // Go to search to find classes
                    child: const Text('Tìm lớp học ngay'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(myEnrolledCoursesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: courses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final course = courses[index];
                return _buildCourseCard(context, course, currencyFormat);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course, NumberFormat currencyFormat) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push('/class-detail', extra: course),
        borderRadius: BorderRadius.circular(16),
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
                      color: _getSubjectColor(course.subject).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.school, color: _getSubjectColor(course.subject)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('${course.subject} - ${course.gradeLevel}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                  _buildStatusBadge(course.status),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('Bắt đầu: ${DateFormat('dd/MM').format(course.startDate)}', style: TextStyle(fontSize: 13, color: Colors.grey[800])),
                  const Spacer(),
                  Icon(Icons.attach_money, size: 14, color: Colors.grey[600]),
                  Text(currencyFormat.format(course.price), style: TextStyle(fontSize: 13, color: Colors.grey[800], fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(child: Text(course.address ?? 'Online', style: TextStyle(fontSize: 13, color: Colors.grey[800]), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'open' ? Colors.green : Colors.grey;
    final text = status == 'open' ? 'Đang học' : 'Kết thúc'; // Simplified status for student view
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Color _getSubjectColor(String subject) {
    if (subject.toLowerCase().contains('toán')) return Colors.blue;
    if (subject.toLowerCase().contains('anh')) return Colors.purple;
    if (subject.toLowerCase().contains('văn')) return Colors.pink;
    return Colors.orange;
  }
}
