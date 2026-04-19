import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:doantotnghiep/core/theme/app_theme.dart';
import '../data/community_repository.dart';

final questionDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  final dynamic response = await ref.read(communityRepositoryProvider).getQuestionDetail(id);
  return response as Map<String, dynamic>;
});

class QuestionDetailScreen extends ConsumerStatefulWidget {
  final int questionId;
  const QuestionDetailScreen({super.key, required this.questionId});

  @override
  ConsumerState<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends ConsumerState<QuestionDetailScreen> {
  final _answerController = TextEditingController();
  bool _isPosting = false;

  Future<void> _postAnswer() async {
    if (_answerController.text.trim().isEmpty) return;

    setState(() => _isPosting = true);
    try {
      await ref.read(communityRepositoryProvider).postAnswer(widget.questionId, _answerController.text);
      _answerController.clear();
      ref.refresh(questionDetailProvider(widget.questionId)); // Refresh data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionAsync = ref.watch(questionDetailProvider(widget.questionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Detail'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: questionAsync.when(
        data: (q) {
          final answers = (q['answers'] as List<dynamic>? ?? []).reversed.toList();
          final user = q['user'] ?? {};
          final date = DateTime.tryParse(q['created_at'] ?? '');

          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    // Question Header
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                               CircleAvatar(
                                radius: 16,
                                backgroundImage: NetworkImage(user['avatar_url'] ?? 'https://via.placeholder.com/150'),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user['name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    if (date != null) Text(DateFormat.yMMMd().add_jm().format(date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(q['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(q['content'] ?? '', style: const TextStyle(fontSize: 16, height: 1.5)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: (q['tags'] as List<dynamic>? ?? []).map<Widget>((tag) {
                              return Chip(label: Text(tag), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap);
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Answers List
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('${answers.length} Answers', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: answers.length,
                      itemBuilder: (context, index) {
                        final a = answers[index];
                        final aUser = a['user'] ?? {};
                        final isAi = a['is_ai_generated'] == true;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isAi ? Colors.blue[50] : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isAi ? Colors.blue[100]! : Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (isAi)
                                     const CircleAvatar(radius: 12, backgroundColor: Colors.blue, child: Icon(Icons.auto_awesome, size: 14, color: Colors.white))
                                  else
                                    CircleAvatar(radius: 12, backgroundImage: NetworkImage(aUser['avatar_url'] ?? 'https://via.placeholder.com/150')),
                                  const SizedBox(width: 8),
                                  Text(isAi ? 'AI Assistant' : (aUser['name'] ?? 'User'), style: TextStyle(fontWeight: FontWeight.bold, color: isAi ? Colors.blue : Colors.black)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(a['content'] ?? ''),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Input Area
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _answerController,
                        decoration: const InputDecoration(
                          hintText: 'Answer this question...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                        onPressed: _isPosting ? null : _postAnswer,
                        icon: _isPosting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
                        color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
