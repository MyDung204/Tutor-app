import 'package:doantotnghiep/features/group/data/course_provider.dart';
import 'package:doantotnghiep/features/auth/data/auth_repository.dart';
import 'package:doantotnghiep/features/group/data/shared_learning_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ClassListingTab extends ConsumerWidget {
  const ClassListingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);
    final user = ref.watch(authRepositoryProvider).currentUser;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              if (user?.role == 'tutor') 
                Expanded(
                  child: InkWell(
                    onTap: () => context.push('/create-class'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.blue.shade600, Colors.blue.shade400]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add, color: Colors.white), Text(' Tạo lớp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                      ]),
                    ),
                  ),
                ),
              if (user?.role == 'tutor') const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => context.push(
                    user?.role == 'tutor' ? '/my-classes' : '/my-enrolled-classes'
                  ),
                   child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.list, color: Colors.blue), Text(' Lớp của tôi', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
                      ]),
                    ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: coursesAsync.when(
            data: (courses) {
              if (courses.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(coursesProvider),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.class_outlined, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              const Text("Chưa có lớp học nào.", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.refresh(coursesProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    // Sử dụng isEnrolled từ Course model (đã được set từ API)
                    final isEnrolled = course.isEnrolled;
        
                  return InkWell(
                    onTap: () {
                      context.push('/class-detail', extra: course);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Container(
                              height: 120,
                              width: double.infinity,
                              color: Colors.blue.shade100,
                              child: Center(
                                child: Icon(Icons.school, size: 60, color: Colors.blue.shade300),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: course.status == 'open' ? Colors.green : Colors.grey,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        course.status == 'open' ? 'Đang tuyển' : 'Đã đóng',
                                        style: const TextStyle(color: Colors.white, fontSize: 10)
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${course.maxStudents} HV max', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                 Text(
                                  course.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Giảng viên: ${course.tutorName}',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Học phí', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                        Text(
                                          currencyFormat.format(course.price),
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)
                                        ),
                                      ],
                                    ),
                                    ElevatedButton(
                                      onPressed: isEnrolled ? null : () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Đăng ký lớp học', style: TextStyle(fontWeight: FontWeight.bold)),
                                            content: const Text('Bạn sẽ được gia nhập lớp và có 7 ngày học thử miễn phí trước khi cần thanh toán học phí. Bạn có muốn tiếp tục?'),
                                            actions: [
                                              TextButton(onPressed: () => ctx.pop(), child: const Text('Hủy')),
                                              FilledButton(
                                                onPressed: () async {
                                                  ctx.pop();
                                                  final success = await ref.read(sharedLearningRepositoryProvider).joinCourse(course.id);
                                                  if (context.mounted) {
                                                     if (success) {
                                                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng ký thành công!')));
                                                       ref.invalidate(coursesProvider);
                                                     } else {
                                                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng ký thất bại. Vui lòng thử lại.')));
                                                     }
                                                  }
                                                },
                                                child: const Text('Đồng ý'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        backgroundColor: isEnrolled ? Colors.grey.shade300 : null,
                                        foregroundColor: isEnrolled ? Colors.black54 : null,
                                      ),
                                      child: Text(isEnrolled ? 'Đã tham gia' : 'Đăng ký'),
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
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Lỗi: $err')),
          ),
        ),
      ],
    );
  }
}
