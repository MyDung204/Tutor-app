import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/controllers/quiz_controller.dart';
import '../../domain/models/quiz.dart';
import '../../../../core/theme/edu_theme.dart';

class QuizDetailScreen extends ConsumerWidget {
  final int quizId;
  final Quiz? initialData;

  const QuizDetailScreen({super.key, required this.quizId, this.initialData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If we passed the full object, use it initially. Otherwise fetch details.
    final quizAsync = ref.watch(quizDetailProvider(quizId));

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết bài thi')),
      body: quizAsync.when(
        data: (quiz) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  quiz.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (quiz.description != null)
                  Text(quiz.description!, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 24),
                _buildInfoCard(
                  context,
                  icon: Icons.person_outline,
                  label: 'Giao bởi',
                  value: quiz.tutor?.name ?? 'Gia sư',
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  context,
                  icon: Icons.timer,
                  label: 'Thời gian làm bài',
                  value: '${quiz.timeLimitMinutes ?? "Không giới hạn"} phút',
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  context,
                  icon: Icons.format_list_numbered,
                  label: 'Số câu hỏi',
                  value: '${quiz.questions.length} câu',
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    // Start Quiz
                    context.replace('/quiz-taking/${quiz.id}', extra: quiz);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EduTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('BẮT ĐẦU LÀM BÀI', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ],
          )
        ],
      ),
    );
  }
}
