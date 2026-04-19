/// Admin Reports Screen
/// 
/// **Purpose:**
/// - Quản lý các báo cáo và khiếu nại từ người dùng
/// - Cho phép admin xem, giải quyết hoặc bỏ qua báo cáo
/// 
/// **Features:**
/// - Xem danh sách báo cáo đang chờ xử lý (status = pending)
/// - Xem chi tiết báo cáo (lý do, mô tả, người báo cáo, đối tượng)
/// - Giải quyết báo cáo (resolve)
/// - Bỏ qua báo cáo (dismiss)
/// - Swipe to dismiss
/// 
/// **Report Status:**
/// - Pending: Đang chờ xử lý (hiển thị trong danh sách)
/// - Resolved: Đã được giải quyết (không hiển thị)
library;

import 'package:doantotnghiep/features/admin/data/admin_reports_provider.dart';
import 'package:doantotnghiep/features/admin/data/admin_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Màn hình quản lý báo cáo của admin
/// 
/// **Usage:**
/// - Truy cập từ admin navigation → "Báo cáo"
/// - Hiển thị danh sách báo cáo đang chờ xử lý
class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(adminReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo & Khiếu nại'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: reportsAsync.when(
        data: (reports) {
           // Lọc chỉ lấy các báo cáo đang chờ xử lý
           final pendingReports = reports.where((r) => r['status'] == 'pending').toList();
           
           // Empty state: Hiển thị khi không có báo cáo nào
           if (reports.isEmpty) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.check_circle_outline, size: 64, color: Colors.green[300]),
                   const SizedBox(height: 16),
                   const Text(
                     "Không có báo cáo nào cần xử lý.",
                     style: TextStyle(fontSize: 16, color: Colors.grey),
                   ),
                 ],
               ),
             );
           }
           
           // Empty state: Tất cả báo cáo đã được giải quyết
           if (pendingReports.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, size: 64, color: Colors.green[300]),
                    const SizedBox(height: 16),
                    const Text(
                      "Tất cả báo cáo đã được giải quyết!",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
           }

           return ListView.builder(
              itemCount: pendingReports.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final report = pendingReports[index];
                return Dismissible(
                  key: Key(report['id'].toString()),
                  onDismissed: (direction) {
                     _handleResolve(report['id']);
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã bỏ qua.')));
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Quan trọng', style: TextStyle(color: Colors.red, fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              Text('Report #${report['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Text(_formatDate(report['created_at']), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(report['reason'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          if (report['description'] != null)
                             Text(report['description'], style: const TextStyle(fontSize: 14)),
                          
                          const SizedBox(height: 8),
                          Text('Báo cáo bởi: ${report['reporter_name']}', style: const TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
                          Text('Đối tượng: ${report['target_name']}', style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
                          
                          const SizedBox(height: 12),
                          // Chức năng giải quyết đơn giản hơn - chỉ một nút
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                // Hiển thị dialog xác nhận
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Xác nhận'),
                                    content: const Text('Bạn có chắc chắn muốn giải quyết khiếu nại này?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Hủy'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                                        child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirmed == true) {
                                  final success = await _handleResolve(report['id']);
                                  if (success && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã giải quyết khiếu nại thành công.')),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.check_circle, size: 20),
                              label: const Text('Đánh dấu đã giải quyết'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }

  /// Xử lý giải quyết báo cáo
  /// 
  /// **Purpose:**
  /// - Gọi API để đánh dấu báo cáo đã được giải quyết
  /// - Refresh danh sách sau khi giải quyết thành công
  /// - Hiển thị thông báo kết quả
  /// 
  /// **Parameters:**
  /// - `id`: ID của báo cáo cần giải quyết
  /// 
  /// **Returns:**
  /// - `bool`: true nếu giải quyết thành công, false nếu thất bại
  Future<bool> _handleResolve(dynamic id) async {
     try {
       final success = await ref.read(adminRepositoryProvider).resolveReport(int.tryParse(id.toString()) ?? 0);
       if (success) {
         // Refresh danh sách
         ref.invalidate(adminReportsProvider);
         return true;
       } else {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Giải quyết báo cáo thất bại. Vui lòng thử lại.'),
               backgroundColor: Colors.red,
             ),
           );
         }
       }
     } catch(e) {
       print('Error resolving report: $e');
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Lỗi: $e'),
             backgroundColor: Colors.red,
           ),
         );
       }
     }
     return false;
  }

  /// Format date string từ ISO format sang định dạng dễ đọc
  /// 
  /// **Purpose:**
  /// - Chuyển đổi ISO date string (e.g., "2024-12-28T10:30:00Z")
  /// - Thành định dạng "dd/MM HH:mm" (e.g., "28/12 10:30")
  /// 
  /// **Parameters:**
  /// - `iso`: ISO date string từ API
  /// 
  /// **Returns:**
  /// - `String`: Formatted date string hoặc original string nếu parse lỗi
  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final date = DateTime.parse(iso);
      return DateFormat('dd/MM HH:mm').format(date);
    } catch (e) {
      print('Error formatting date: $e');
      return iso;
    }
  }
}
