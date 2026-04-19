import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doantotnghiep/features/tutor/data/tutor_repository.dart';

// Provider cho Thống kê (Statistics)
final tutorStatisticsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(tutorRepositoryProvider);
  return await repository.getMyStatistics();
});

// Provider cho Học phí (Tuitions)
final tutorTuitionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(tutorRepositoryProvider);
  return await repository.getMyTuitions();
});
