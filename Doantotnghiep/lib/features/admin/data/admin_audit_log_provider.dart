import 'package:doantotnghiep/features/admin/data/admin_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminAuditLogsProvider = FutureProvider.autoDispose.family<List<dynamic>, String?>((ref, type) async {
  return ref.watch(adminRepositoryProvider).getAuditLogs(type: type ?? 'alert');
});
