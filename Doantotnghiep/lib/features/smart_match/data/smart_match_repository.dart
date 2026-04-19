import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doantotnghiep/core/network/api_client.dart';

final smartMatchRepositoryProvider = Provider<SmartMatchRepository>((ref) {
  return SmartMatchRepository(ref.read(apiClientProvider));
});

class SmartMatchRepository {
  final ApiClient _apiClient;

  SmartMatchRepository(this._apiClient);

  Future<List<dynamic>> getMatches(List<String> tags) async {
    try {
      final response = await _apiClient.post('/smart-match', data: {'tags': tags});
      return response.data['data'];
    } catch (e) {
      throw e;
    }
  }

  Future<void> saveLearningTags(List<String> tags) async {
    try {
      await _apiClient.post('/user/learning-tags', data: {'tags': tags});
    } catch (e) {
      throw e;
    }
  }
}
