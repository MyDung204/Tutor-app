import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../domain/models/quiz.dart';
import '../domain/models/quiz_attempt.dart';

class QuizRepository {
  final ApiClient _apiClient;

  QuizRepository(this._apiClient);

  Future<List<Quiz>> getQuizzes({int? tutorId}) async {
    final response = await _apiClient.get(
      '/quizzes',
      queryParameters: tutorId != null ? {'tutor_id': tutorId} : null,
    );
    return (response.data as List).map((e) => Quiz.fromJson(e)).toList();
  }

  Future<Quiz> getQuizDetail(int id) async {
    final response = await _apiClient.get('/quizzes/$id');
    return Quiz.fromJson(response.data);
  }

  Future<Quiz> createQuiz(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/quizzes', data: data);
    return Quiz.fromJson(response.data);
  }

  Future<Map<String, dynamic>> submitQuiz(int id, List<Map<String, dynamic>> answers) async {
    final response = await _apiClient.post(
      '/quizzes/$id/submit',
      data: {'answers': answers},
    );
    return response.data;
  }

  Future<List<QuizAttempt>> getAttempts() async {
    final response = await _apiClient.get('/my-quiz-attempts');
    return (response.data as List).map((e) => QuizAttempt.fromJson(e)).toList();
  }
}

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository(ref.watch(apiClientProvider));
});
