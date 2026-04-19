import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz.dart';
import '../models/quiz_attempt.dart';
import '../../data/quiz_repository.dart';

// List of quizzes (Support filtering by tutorId later if needed)
final quizListProvider = FutureProvider.family<List<Quiz>, int?>((ref, tutorId) async {
  final repository = ref.watch(quizRepositoryProvider);
  return repository.getQuizzes(tutorId: tutorId);
});

// Quiz Detail
final quizDetailProvider = FutureProvider.family<Quiz, int>((ref, quizId) async {
  final repository = ref.watch(quizRepositoryProvider);
  return repository.getQuizDetail(quizId);
});

// My Attempts
final myQuizAttemptsProvider = FutureProvider<List<QuizAttempt>>((ref) async {
  final repository = ref.watch(quizRepositoryProvider);
  return repository.getAttempts();
});

// Actions Controller (Create, Submit)
class QuizActionController extends StateNotifier<AsyncValue<void>> {
  final QuizRepository _repository;

  QuizActionController(this._repository) : super(const AsyncValue.data(null));

  Future<Quiz?> createQuiz(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final quiz = await _repository.createQuiz(data);
      state = const AsyncValue.data(null);
      return quiz;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<Map<String, dynamic>?> submitQuiz(int quizId, List<Map<String, dynamic>> answers) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.submitQuiz(quizId, answers);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final quizActionProvider = StateNotifierProvider<QuizActionController, AsyncValue<void>>((ref) {
  return QuizActionController(ref.watch(quizRepositoryProvider));
});
