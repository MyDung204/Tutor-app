import 'package:doantotnghiep/core/theme/edu_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/controllers/quiz_controller.dart';
import '../../domain/models/quiz.dart';

class StudentQuizListScreen extends ConsumerWidget {
  const StudentQuizListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizListAsync = ref.watch(quizListProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài trắc nghiệm'),
      ),
      body: quizListAsync.when(
        data: (quizzes) {
          if (quizzes.isEmpty) {
            return const Center(child: Text('Chưa có bài kiểm tra nào.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: quizzes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final quiz = quizzes[index];
              return _QuizCard(quiz: quiz);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final Quiz quiz;

  const _QuizCard({required this.quiz});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          context.push('/quiz-detail/${quiz.id}', extra: quiz);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quiz.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (quiz.description != null) ...[
                Text(
                  quiz.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 16, color: EduTheme.primary),
                  const SizedBox(width: 4),
                  Text('${quiz.timeLimitMinutes ?? "∞"} phút'),
                  const Spacer(),
                  Icon(Icons.help_outline, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('${quiz.questions.length} câu hỏi'), // Note: list might not be populated in index
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
