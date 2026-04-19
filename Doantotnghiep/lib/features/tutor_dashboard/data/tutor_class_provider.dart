import 'package:doantotnghiep/features/group/data/shared_learning_repository.dart';
import 'package:doantotnghiep/features/group/domain/models/course.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TutorClassNotifier extends AsyncNotifier<List<Course>> {
  @override
  Future<List<Course>> build() async {
    final repo = ref.watch(sharedLearningRepositoryProvider);
    try {
      final courses = await repo.getMyCourses();
      return courses;
    } catch (e) {
      print('Error loading tutor classes: $e');
      return [];
    }
  }

  // Helper methods to refresh
  void refresh() {
    ref.invalidateSelf();
  }
}

final tutorClassProvider = AsyncNotifierProvider<TutorClassNotifier, List<Course>>(TutorClassNotifier.new);
