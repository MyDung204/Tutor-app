import 'package:doantotnghiep/features/admin/data/admin_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for Alerts (Warnings/Danger)
final auditAlertsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final data = await repo.getAuditLogs(type: 'alert');
  return data.map((e) => e as Map<String, dynamic>).toList();
});

// Provider for Scan Logs (Info/Success)
final auditLogsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final data = await repo.getAuditLogs(type: 'scan_log');
  return data.map((e) => e as Map<String, dynamic>).toList();
});
