/// Admin Course Approval Screen
/// 
/// **Purpose:**
/// - Quản lý các khóa học chờ duyệt
/// - Cho phép admin duyệt hoặc từ chối khóa học
/// 
/// **Features:**
/// - Xem danh sách khóa học chờ duyệt
/// - Duyệt khóa học (approve)
/// - Từ chối khóa học (reject)
/// - Swipe to approve/reject
library;

import 'package:doantotnghiep/features/admin/data/admin_repository.dart';
import 'package:doantotnghiep/features/admin/data/admin_course_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AdminCourseApprovalScreen extends ConsumerStatefulWidget {
  const AdminCourseApprovalScreen({super.key});

  @override
  ConsumerState<AdminCourseApprovalScreen> createState() => _AdminCourseApprovalScreenState();
}

class _AdminCourseApprovalScreenState extends ConsumerState<AdminCourseApprovalScreen> {

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(adminPendingCoursesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Phê duyệt Khóa học'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: coursesAsync.when(
        data: (courses) {
           if (courses.isEmpty) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.check_circle_outline, size: 64, color: Colors.green[300]),
                   const SizedBox(height: 16),
                   const Text(
                     'Không có khóa học nào đang chờ.',
                     style: TextStyle(fontSize: 16, color: Colors.grey),
                   ),
                 ],
               ),
             );
           }
           return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return Dismissible(
                  key: Key(course['id'].toString()),
                  background: _buildSwipeAction(Colors.green, Icons.check, Alignment.centerLeft),
                  secondaryBackground: _buildSwipeAction(Colors.red, Icons.close, Alignment.centerRight),
                   confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                       return await _handleApprove(course);
                    } else {
                       return await _handleReject(course);
                    }
                  },
                  child: _buildCourseCard(course),
                );
              },
            );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
      )
    );
  }

  Widget _buildSwipeAction(Color color, IconData icon, Alignment alignment) {
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 16),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final currencyFormat = NumberFormat.compactCurrency(locale: 'vi_VN', symbol: 'đ');
    final price = course['price'] is num ? currencyFormat.format(course['price']) : '${course['price']}';

    return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.class_outlined, color: Colors.blue, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course['title'] ?? 'No Title',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gia sư: ${course['tutor']?['name'] ?? 'Unknown'}',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Môn: ${course['subject'] ?? 'N/A'} - $price',
                          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Từ chối', style: TextStyle(color: Colors.red)),
                    onPressed: () => _handleReject(course),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Duyệt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => _handleApprove(course),
                  ),
                ],
              )
            ],
          ),
        ),
      );
  }

  Future<bool> _handleApprove(Map<String, dynamic> course) async {
     try {
       final success = await ref.read(adminRepositoryProvider).approveCourse(course['id']);
       if (success) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Đã duyệt khóa học'), backgroundColor: Colors.green),
           );
         }
         ref.invalidate(adminPendingCoursesProvider);
         return true;
       }
     } catch (e) {
        print(e);
     }
     return false;
  }

  Future<bool> _handleReject(Map<String, dynamic> course) async {
      try {
       final success = await ref.read(adminRepositoryProvider).rejectCourse(course['id']);
       if (success) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Đã từ chối khóa học'), backgroundColor: Colors.orange),
           );
         }
         ref.invalidate(adminPendingCoursesProvider);
         return true;
       }
     } catch (e) {
        print(e);
     }
     return false;
  }
}
