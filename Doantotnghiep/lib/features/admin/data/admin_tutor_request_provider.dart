import 'package:doantotnghiep/features/admin/data/admin_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doantotnghiep/features/tutor/domain/models/tutor.dart';

final tutorRequestsProvider = FutureProvider.autoDispose<List<Tutor>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final data = await repo.getTutorRequests();
  
  return data.map((json) => Tutor.fromJson(json as Map<String, dynamic>)).toList();
});
