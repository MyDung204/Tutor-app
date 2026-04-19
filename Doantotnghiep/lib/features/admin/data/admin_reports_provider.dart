import 'package:doantotnghiep/features/admin/data/admin_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminReportsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final data = await repo.getReports();
  // Ensure the list is a list of maps
  return data.map((e) => e as Map<String, dynamic>).toList();
});
