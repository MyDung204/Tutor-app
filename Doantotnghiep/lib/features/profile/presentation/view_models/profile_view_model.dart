import 'dart:async';
import 'package:doantotnghiep/features/auth/data/auth_repository.dart';
import 'package:doantotnghiep/features/auth/domain/models/app_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileViewModelProvider = AsyncNotifierProvider<ProfileViewModel, AppUser?>(() {
  return ProfileViewModel();
});

class ProfileViewModel extends AsyncNotifier<AppUser?> {
  @override
  FutureOr<AppUser?> build() async {
    // Sync with Auth State
    final authUser = ref.watch(authStateChangesProvider).value;
    return authUser;
  }

  Future<void> refreshProfile() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // For now, we just mock a refresh by reading current user from repo
      // In real implementation, this should call an API endpoint like /me
      final currentUser = ref.read(authRepositoryProvider).currentUser;
      return currentUser;
    });
  }

  Future<void> logout() async {
     await ref.read(authRepositoryProvider).signOut();
  }
}
