import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:doantotnghiep/core/theme/app_theme.dart';
import '../data/community_repository.dart';
import 'question_detail_screen.dart';

final questionsProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, page) async {
  return ref.read(communityRepositoryProvider).getQuestions(page);
});

class QuestionListTab extends ConsumerWidget {
  final String filter;
  const QuestionListTab({super.key, required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionsProvider(1)); // Simple pagination for now

    return questionsAsync.when(
      data: (data) {
        final questions = data['data'] as List<dynamic>;
        if (questions.isEmpty) {
          return const Center(child: Text('No questions found. Be the first to ask!'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: questions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final q = questions[index];
            final user = q['user'] ?? {};
            final answersCount = (q['answers'] as List?)?.length ?? 0;
            final date = DateTime.tryParse(q['created_at'] ?? '');
            final dateStr = date != null ? DateFormat.yMMMd().format(date) : '';

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () {
                     Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuestionDetailScreen(questionId: q['id'])));
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundImage: NetworkImage(user['avatar_url'] ?? 'https://via.placeholder.com/150'),
                          ),
                          const SizedBox(width: 8),
                          Text(user['name'] ?? 'Anonymous', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const Spacer(),
                          Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        q['title'] ?? 'No Title',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        q['content'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                          Text('$answersCount Answers', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
                          const SizedBox(width: 16),
                          const Icon(Icons.visibility_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${q['views']} Views', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
