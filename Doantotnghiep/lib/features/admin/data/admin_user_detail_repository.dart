import 'package:doantotnghiep/core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminUserDetailRepositoryProvider = Provider((ref) => AdminUserDetailRepository(ref.read(apiClientProvider)));

class AdminUserDetailRepository {
  final ApiClient _apiService;

  AdminUserDetailRepository(this._apiService);

  Future<Map<String, dynamic>> getUserDetail(int id) async {
    try {
      final response = await _apiService.get('/admin/users/$id');
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<bool> updateUser(int id, Map<String, dynamic> data) async {
    try {
      await _apiService.put('/admin/users/$id', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleBan(int id) async {
    try {
      await _apiService.post('/admin/users/$id/ban', data: {});
      return true;
    } catch (e) {
      return false;
    }
  }
  Future<List<dynamic>> getUserActivities(int id) async {
    try {
      final response = await _apiService.get('/admin/users/$id/activities');
      return response as List<dynamic>;
    } catch (e) {
      return [];
    }
  }
}
