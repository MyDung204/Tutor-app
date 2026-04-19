import 'package:doantotnghiep/features/group/data/shared_learning_repository.dart';
import 'package:doantotnghiep/features/group/domain/models/course.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final coursesProvider = FutureProvider.autoDispose<List<Course>>((ref) async {
  final repo = ref.watch(sharedLearningRepositoryProvider);
  return repo.getCourses();
});
