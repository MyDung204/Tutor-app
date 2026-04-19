import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/quiz.dart';
import '../../../../core/theme/edu_theme.dart';

class QuizResultScreen extends StatelessWidget {
  final Quiz quiz;
  final Map<String, dynamic> result;

  const QuizResultScreen({super.key, required this.quiz, required this.result});

  @override
  Widget build(BuildContext context) {
    final double score = (result['score'] as num).toDouble();
    final double totalPoints = (result['total_points'] as num).toDouble();
    final Map<String, dynamic> correctAnswers = result['correct_answers']; // question_id -> option_id

    final percentage = (score / totalPoints) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả bài thi'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/quizzes'), // Go back to list
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Score Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                children: [
                  const Text('Điểm của bạn', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 12),
                  Text(
                    '${score.toStringAsFixed(1)} / $totalPoints',
                    style: TextStyle(
                      fontSize: 40, 
                      fontWeight: FontWeight.bold, 
                      color: percentage >= 50 ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    percentage >= 80 ? 'Xuất sắc! 🎉' : (percentage >= 50 ? 'Đạt yêu cầu 👍' : 'Cần cố gắng hơn 💪'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Result Details
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Chi tiết đáp án', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quiz.questions.length,
              itemBuilder: (context, index) {
                final question = quiz.questions[index];
                // Check if user's answer matched correct answer logic is complex here without full submission details.
                // Simplified: Just show the correct answer highlight.
                // Ideally, we should pass selected answers too to show what user chose vs correct.
                // For now, let's just list the questions and indicate the correct answer.
                
                final correctOptionId = correctAnswers[question.id.toString()] ?? correctAnswers[question.id];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Câu ${index + 1}: ${question.content}', 
                             style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 12),
                        ...question.options.map((option) {
                          final isCorrect = option.id == correctOptionId;
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: isCorrect ? Colors.green[50] : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isCorrect ? Border.all(color: Colors.green) : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: isCorrect ? Colors.green : Colors.grey,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(option.content, style: TextStyle(
                                  color: isCorrect ? Colors.green[900] : Colors.black87,
                                  fontWeight: isCorrect ? FontWeight.w500 : FontWeight.normal
                                )),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
            
             const SizedBox(height: 20),
             SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 onPressed: () => context.go('/quizzes'),
                 child: const Text('Quay về danh sách'),
               ),
             ),
          ],
        ),
      ),
    );
  }
}
