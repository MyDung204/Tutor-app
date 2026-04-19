import 'package:doantotnghiep/core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminFinanceRepositoryProvider = Provider((ref) => AdminFinanceRepository(ref.read(apiClientProvider)));

class AdminFinanceRepository {
  final ApiClient _apiService;

  AdminFinanceRepository(this._apiService);

  Future<List<dynamic>> getWithdrawals({String status = 'pending'}) async {
    try {
      final response = await _apiService.get('/admin/withdrawals?status=$status');
      if (response.statusCode == 200) {
        return (response.data['data'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> approveWithdrawal(int id) async {
    try {
      final response = await _apiService.post('/admin/withdrawals/$id/approve', data: {});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectWithdrawal(int id, String reason) async {
    try {
      final response = await _apiService.post('/admin/withdrawals/$id/reject', data: {'reason': reason});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
