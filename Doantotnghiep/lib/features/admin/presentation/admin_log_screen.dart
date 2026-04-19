/// Admin Activity Log Screen
/// 
/// **Purpose:**
/// - Xem nhật ký hoạt động hệ thống (System Logs)
/// - Theo dõi các hành động quan trọng (Login, Update, Delete, Error)
/// - Filter theo loại log (Info, Warning, Error, Alert)
library;

import 'package:doantotnghiep/features/admin/data/admin_audit_log_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AdminLogScreen extends ConsumerStatefulWidget {
  const AdminLogScreen({super.key});

  @override
  ConsumerState<AdminLogScreen> createState() => _AdminLogScreenState();
}

class _AdminLogScreenState extends ConsumerState<AdminLogScreen> {
  String _selectedType = 'alert'; // Default filter

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(adminAuditLogsProvider(_selectedType));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Nhật ký hệ thống'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedType = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'alert', child: Text('Cảnh báo (Alert)')),
              const PopupMenuItem(value: 'info', child: Text('Thông tin (Info)')),
              const PopupMenuItem(value: 'error', child: Text('Lỗi (Error)')),
               const PopupMenuItem(value: 'all', child: Text('Tất cả')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Text('Đang xem: ${_getLabel(_selectedType)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () => ref.invalidate(adminAuditLogsProvider),
                ),
              ],
            ),
          ),
          Expanded(
            child: logsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return const Center(child: Text('Không có nhật ký nào.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    return _buildLogCard(logs[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Lỗi: $err')),
            ),
          ),
        ],
      ),
    );
  }

  String _getLabel(String type) {
    switch (type) {
      case 'alert': return 'Cảnh báo';
      case 'info': return 'Thông tin';
      case 'error': return 'Lỗi';
      default: return 'Tất cả';
    }
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final type = log['type'] ?? 'info';
    final message = log['message'] ?? '';
    final createdAt = log['created_at'] != null 
        ? DateFormat('dd/MM HH:mm:ss').format(DateTime.parse(log['created_at']))
        : '';
    
    Color color = Colors.blue;
    IconData icon = Icons.info_outline;

    if (type == 'error') {
      color = Colors.red;
      icon = Icons.error_outline;
    } else if (type == 'alert') {
      color = Colors.orange;
      icon = Icons.warning_amber_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                // Optional: Show detail data if available
                if (log['data'] != null)
                   Text(log['data'].toString(), style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'monospace')),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(createdAt, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
