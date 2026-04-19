import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doantotnghiep/features/admin/data/admin_repository.dart';

final adminDashboardStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getDashboardStats();
});
