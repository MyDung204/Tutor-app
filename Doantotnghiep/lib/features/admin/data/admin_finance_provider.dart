import 'package:doantotnghiep/features/admin/data/admin_finance_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to fetch withdrawal requests (auto-disposes to refresh on re-entry)
final adminWithdrawalRequestsProvider = FutureProvider.autoDispose.family<List<dynamic>, String>((ref, status) async {
  final repository = ref.read(adminFinanceRepositoryProvider);
  return repository.getWithdrawals(status: status);
});
