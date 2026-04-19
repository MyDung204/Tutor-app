import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doantotnghiep/core/network/api_client.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(ref.read(apiClientProvider));
});

class CommunityRepository {
  final ApiClient _apiClient;

  CommunityRepository(this._apiClient);

  Future<Map<String, dynamic>> getQuestions(int page) async {
    try {
      final response = await _apiClient.get('/questions', queryParameters: {'page': page});
      return response.data;
    } catch (e) {
      throw e;
    }
  }

  Future<dynamic> getQuestionDetail(int id) async {
    try {
      final response = await _apiClient.get('/questions/$id');
      return response.data;
    } catch (e) {
      throw e;
    }
  }

  Future<void> createQuestion(String title, String content, List<String> tags) async {
    try {
      await _apiClient.post('/questions', data: {
        'title': title,
        'content': content,
        'tags': tags,
      });
    } catch (e) {
      throw e;
    }
  }

  Future<void> postAnswer(int questionId, String content) async {
    try {
      await _apiClient.post('/questions/$questionId/answers', data: {
        'content': content,
      });
    } catch (e) {
      throw e;
    }
  }
}
