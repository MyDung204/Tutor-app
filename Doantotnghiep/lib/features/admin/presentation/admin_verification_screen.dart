/// Admin Verification Screen (eKYC)
/// 
/// **Purpose:**
/// - Quản lý các yêu cầu xác thực danh tính (KYC)
/// - Xem ảnh CMND/CCCD mặt trước, mặt sau
/// - Duyệt hoặc từ chối yêu cầu
/// 
/// **Features:**
/// - List pending requests
/// - Detail view (Card) with images
/// - Approve/Reject actions
library;

import 'package:doantotnghiep/features/admin/data/admin_repository.dart';
import 'package:doantotnghiep/features/admin/data/admin_verification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AdminVerificationScreen extends ConsumerStatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  ConsumerState<AdminVerificationScreen> createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends ConsumerState<AdminVerificationScreen> {
  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(adminVerificationRequestsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Duyệt hồ sơ KYC'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_turned_in, size: 64, color: Colors.green[300]),
                  const SizedBox(height: 16),
                  const Text('Không có yêu cầu xác thực nào.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return _buildRequestCard(req);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final user = req['user'] ?? {};
    final createdAt = req['created_at'] != null 
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(req['created_at']))
        : 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                  child: user['avatar_url'] == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(user['email'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Pending', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Đã gửi: $createdAt', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            const Text('Ảnh xác thực:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildImagePreview('Mặt trước', req['front_image_url'])),
                const SizedBox(width: 12),
                Expanded(child: _buildImagePreview('Mặt sau', req['back_image_url'])),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleReject(req),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleApprove(req),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Duyệt'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(String label, String? url) {
    return Column(
      children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            image: url != null ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
          ),
          child: url == null ? const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)) : null,
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Future<void> _handleApprove(Map<String, dynamic> req) async {
    final success = await ref.read(adminRepositoryProvider).approveVerification(req['id']);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã duyệt hồ sơ'), backgroundColor: Colors.green));
      ref.invalidate(adminVerificationRequestsProvider);
    }
  }

  Future<void> _handleReject(Map<String, dynamic> req) async {
    final noteController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối hồ sơ'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(labelText: 'Lý do từ chối', hintText: 'Ảnh mờ, thông tin không khớp...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Từ chối')),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(adminRepositoryProvider).rejectVerification(req['id'], noteController.text);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã từ chối hồ sơ'), backgroundColor: Colors.orange));
        ref.invalidate(adminVerificationRequestsProvider);
      }
    }
  }
}
