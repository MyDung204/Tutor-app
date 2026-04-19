/// Admin AI Audit Screen
/// 
/// **Purpose:**
/// - Màn hình giám sát hệ thống bằng AI
/// - Hiển thị cảnh báo thời gian thực và nhật ký quét tin nhắn
/// 
/// **Features:**
/// - Cảnh báo thời gian thực: Các cảnh báo về hoạt động bất thường
/// - Nhật ký quét tin nhắn: Lịch sử quét tin nhắn bằng AI để phát hiện spam, lừa đảo
/// - Xử lý cảnh báo (mock - cần implement)
/// 
/// **AI Scanning:**
/// - Quét tin nhắn tự động để phát hiện:
///   - Spam messages
///   - Fraud attempts
///   - Inappropriate content
///   - Suspicious behavior
library;

import 'package:doantotnghiep/features/admin/data/admin_audit_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Màn hình giám sát AI của admin
/// 
/// **Usage:**
/// - Truy cập từ admin navigation → "Mắt thần"
/// - Hiển thị cảnh báo và nhật ký quét AI
class AdminAiAuditScreen extends ConsumerWidget {
  const AdminAiAuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(auditAlertsProvider);
    final logsAsync = ref.watch(auditLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mắt Thần AI - Giám Sát'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Cảnh báo Thời gian thực (Real-time)', Icons.warning_amber_rounded, Colors.red),
            const SizedBox(height: 12),
            alertsAsync.when(
              data: (alerts) {
                if (alerts.isEmpty) return const Text('Hệ thống an toàn. Không có cảnh báo.', style: TextStyle(color: Colors.green));
                return Column(
                  children: alerts.map((alert) => _buildAlertCard(
                    context,
                    alert['title'] ?? 'Cảnh báo',
                    alert['description'] ?? '',
                    alert['severity'] == 'danger' ? 'Nguy hiểm cao' : 'Cảnh báo',
                    alert['severity'] == 'danger' ? Colors.red : Colors.orange,
                  )).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Lỗi tải cảnh báo: $err'),
            ),
            
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Nhật ký Quét Tin nhắn (AI Scan)', Icons.message_outlined, Colors.blue),
            const SizedBox(height: 12),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              height: 300, 
              child: logsAsync.when(
                data: (logs) {
                  if (logs.isEmpty) return const Center(child: Text("Chưa có nhật ký quét."));
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '[${_formatTime(log['created_at'])}] AI Scan:',
                              style: const TextStyle(fontFamily: 'monospace', color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                log['description'] ?? '',
                                style: TextStyle(
                                  color: log['severity'] == 'success' ? Colors.green : Colors.orange, 
                                  fontSize: 13
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                 loading: () => const Center(child: CircularProgressIndicator()),
                 error: (err, _) => Center(child: Text('Lỗi: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String? iso) {
    if (iso == null) return '00:00';
    try {
      return DateFormat('HH:mm').format(DateTime.parse(iso));
    } catch (e) { return '00:00'; }
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAlertCard(BuildContext context, String title, String description, String badge, Color badgeColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: badgeColor,
                  side: BorderSide(color: badgeColor),
                ),
                child: const Text('Xử lý ngay (Mock)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
