import 'package:doantotnghiep/features/admin/data/admin_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminPendingCoursesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ref.watch(adminRepositoryProvider).getPendingCourses();
});
