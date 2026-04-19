import 'package:doantotnghiep/features/admin/data/admin_user_detail_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminUserDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, userId) async {
  final repository = ref.read(adminUserDetailRepositoryProvider);
  return repository.getUserDetail(userId);
});
