import 'package:doantotnghiep/features/quiz/domain/controllers/quiz_controller.dart';
import 'package:doantotnghiep/features/quiz/domain/models/quiz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TutorQuizManagementScreen extends ConsumerWidget {
  const TutorQuizManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // tutorId = null means we fetch the current user's quizzes based on the API endpoint logic
    final quizzesAsync = ref.watch(quizListProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Bài Kiểm Tra'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(quizListProvider(null).future),
        child: quizzesAsync.when(
          skipLoadingOnRefresh: true,
          data: (quizzes) {
            if (quizzes.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.quiz_outlined, size: 80, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Bạn chưa tạo bài kiểm tra nào',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/tutor-create-quiz'),
                            icon: const Icon(Icons.add),
                            label: const Text('Tạo ngay'),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                return _QuizItemCard(quiz: quiz);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(child: Text('Lỗi tải dữ liệu: $error')),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tutor-create-quiz'),
        icon: const Icon(Icons.add),
        label: const Text('Tạo bài KT'),
      ),
    );
  }
}

class _QuizItemCard extends StatelessWidget {
  final Quiz quiz;
  const _QuizItemCard({required this.quiz});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(quiz.description ?? 'Không có mô tả', maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('${quiz.timeLimitMinutes ?? 0} phút', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: quiz.isPublished ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: quiz.isPublished ? Colors.green : Colors.orange, width: 0.5),
                  ),
                  child: Text(
                    quiz.isPublished ? 'Đã xuất bản' : 'Bản nháp',
                    style: TextStyle(
                      fontSize: 10,
                      color: quiz.isPublished ? Colors.green.shade700 : Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          // Future scope: View quiz details / Edit quiz
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tính năng chỉnh sửa bài kiểm tra sẽ được cập nhật sau.')),
          );
        },
      ),
    );
  }
}
