import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doantotnghiep/features/admin/data/admin_repository.dart';
// Subject model is handled as dynamic Map for flexibility

final adminSubjectsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.getSubjects();
});
