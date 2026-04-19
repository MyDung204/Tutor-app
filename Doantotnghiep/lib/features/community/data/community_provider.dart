import 'package:doantotnghiep/core/network/api_client.dart';
import 'package:doantotnghiep/core/network/api_constants.dart';
import 'package:doantotnghiep/features/community/domain/models/question.dart';
import 'package:doantotnghiep/features/community/domain/models/answer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommunityNotifier extends AsyncNotifier<List<Question>> {
  @override
  Future<List<Question>> build() async {
    final apiClient = ref.read(apiClientProvider);
    try {
      // Call Laravel API: GET /questions
      final response = await apiClient.get(ApiConstants.questions);
      if (response is List) {
        return response.map((e) => Question.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('API Error (Questions): $e');
      return []; 
    }
  }

  Future<void> addQuestion(Question q) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      // Call Laravel API: POST /questions
      await apiClient.post(ApiConstants.questions, data: {
        'user_id': q.userId,
        'user_name': q.userName,
        'user_avatar': q.userAvatar,
        'subject': q.subject,
        'content': q.content,
        'image_url': q.imageUrl,
        // Backend handles created_at
      });
      
      // Refresh list to show new item
      ref.invalidateSelf();
    } catch (e) {
      print('API Error (Add Question): $e');
    }
  }

  Future<void> addAnswer(String questionId, Answer answer) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      // Call Laravel API: POST /questions/{id}/answers
      await apiClient.post('${ApiConstants.questions}/$questionId/answers', data: {
         'user_id': answer.userId,
         'content': answer.content,
      });

      // Refresh list
      ref.invalidateSelf();
    } catch (e) {
      print('API Error (Add Answer): $e');
    }
  }
}

final communityProvider = AsyncNotifierProvider<CommunityNotifier, List<Question>>(CommunityNotifier.new);
