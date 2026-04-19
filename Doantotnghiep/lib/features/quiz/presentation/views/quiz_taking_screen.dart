import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/controllers/quiz_controller.dart';
import '../../domain/models/quiz.dart';
import '../../../../core/theme/edu_theme.dart';

class QuizTakingScreen extends ConsumerStatefulWidget {
  final int quizId;
  final Quiz quiz;

  const QuizTakingScreen({super.key, required this.quizId, required this.quiz});

  @override
  ConsumerState<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends ConsumerState<QuizTakingScreen> {
  late PageController _pageController;
  int _currentQuestionIndex = 0;
  
  // Map<QuestionID, OptionID>
  final Map<int, int> _answers = {};
  
  Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Initialize Timer
    if (widget.quiz.timeLimitMinutes != null && widget.quiz.timeLimitMinutes! > 0) {
      _secondsRemaining = widget.quiz.timeLimitMinutes! * 60;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        _submitQuiz(isTimeout: true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _submitQuiz({bool isTimeout = false}) async {
    _timer?.cancel();
    
    // Transform answers map to List<Map> for API
    final submissionData = _answers.entries.map((e) => {
      'question_id': e.key,
      'option_id': e.value,
    }).toList();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await ref.read(quizActionProvider.notifier).submitQuiz(widget.quiz.id, submissionData);

    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading

    if (result != null) {
      // Success -> Go to Result
      context.replace('/quiz-result', extra: {'quiz': widget.quiz, 'result': result});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nộp bài thất bại. Vui lòng thử lại.')),
      );
    }
  }

  void _onOptionSelected(int questionId, int optionId) {
    setState(() {
      _answers[questionId] = optionId;
    });
  }

  String get _timerText {
    if (widget.quiz.timeLimitMinutes == null) return "∞";
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        automaticallyImplyLeading: false, // Prevent back
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: _secondsRemaining < 60 && widget.quiz.timeLimitMinutes != null 
                  ? Colors.red[100] 
                  : Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _secondsRemaining < 60 && widget.quiz.timeLimitMinutes != null
                 ? Colors.red 
                 : Colors.blue,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, size: 16, 
                  color: _secondsRemaining < 60 && widget.quiz.timeLimitMinutes != null ? Colors.red : Colors.blue),
                const SizedBox(width: 4),
                Text(
                  _timerText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _secondsRemaining < 60 && widget.quiz.timeLimitMinutes != null ? Colors.red : Colors.blue,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(EduTheme.primary),
          ),
          
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable swipe
              itemCount: widget.quiz.questions.length,
              itemBuilder: (context, index) {
                final question = widget.quiz.questions[index];
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Câu hỏi ${index + 1}/${widget.quiz.questions.length}',
                        style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        question.content,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 24),
                      
                      ...question.options.map((option) {
                        final isSelected = _answers[question.id] == option.id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? EduTheme.primary.withOpacity(0.1) : Colors.white,
                            border: Border.all(
                              color: isSelected ? EduTheme.primary : Colors.grey[300]!,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => _onOptionSelected(question.id!, option.id!),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Radio<int>(
                                    value: option.id!,
                                    groupValue: _answers[question.id],
                                    onChanged: (val) => _onOptionSelected(question.id!, val!),
                                    activeColor: EduTheme.primary,
                                  ),
                                  Expanded(child: Text(option.content)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentQuestionIndex > 0)
                  OutlinedButton(
                    onPressed: () {
                      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      setState(() => _currentQuestionIndex--);
                    },
                    child: const Text('Quay lại'),
                  )
                else
                  const SizedBox(),
                  
                if (_currentQuestionIndex < widget.quiz.questions.length - 1)
                  ElevatedButton(
                    onPressed: () {
                       _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                       setState(() => _currentQuestionIndex++);
                    },
                    child: const Text('Tiếp theo'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _submitQuiz,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('NỘP BÀI'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
