import 'dart:async';
import 'package:doantotnghiep/features/tutor/data/tutor_repository.dart';
import 'package:doantotnghiep/features/tutor/domain/models/tutor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tutorViewModelProvider = AsyncNotifierProvider<TutorViewModel, List<Tutor>>(() {
  return TutorViewModel();
});

class TutorViewModel extends AsyncNotifier<List<Tutor>> {
  @override
  FutureOr<List<Tutor>> build() async {
    return _getFeaturedTutors();
  }

  Future<List<Tutor>> _getFeaturedTutors() async {
    return await ref.read(tutorRepositoryProvider).getFeaturedTutors();
  }

  Future<void> search(String query) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await ref.read(tutorRepositoryProvider).searchTutors(query);
    });
  }
}
