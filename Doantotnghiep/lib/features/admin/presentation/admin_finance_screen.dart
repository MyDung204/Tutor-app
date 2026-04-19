import 'package:doantotnghiep/features/admin/data/admin_finance_provider.dart';
import 'package:doantotnghiep/features/admin/data/admin_finance_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AdminFinanceScreen extends ConsumerStatefulWidget {
  const AdminFinanceScreen({super.key});

  @override
  ConsumerState<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends ConsumerState<AdminFinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Quản lý Tài chính', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'Yêu cầu Rút tiền'),
            Tab(text: 'Lịch sử Giao dịch'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestList('pending'),
          _buildRequestList('approved'), // Can change to 'history' if supported by API/Filter
        ],
      ),
    );
  }

  Widget _buildRequestList(String status) {
    final requestsAsync = ref.watch(adminWithdrawalRequestsProvider(status)); // Fetch based on status

    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(status == 'pending' ? Icons.account_balance_wallet_outlined : Icons.history, 
                     size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  status == 'pending' ? 'Không có yêu cầu rút tiền nào.' : 'Chưa có lịch sử giao dịch.',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            return _buildRequestCard(req, status == 'pending');
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Lỗi: $err')),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req, bool isPending) {
    final user = req['user'] ?? {};
    final amount = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(double.parse(req['amount'].toString()));
    final createdAt = req['created_at'] != null 
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(req['created_at']))
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                  child: user['avatar_url'] == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'] ?? 'Tutor', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(createdAt, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.account_balance, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${req['bank_name']} - ${req['bank_account_number']}\n${req['bank_account_name']}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleReject(req['id']),
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
                      onPressed: () => _handleApprove(req['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Duyệt'),
                    ),
                  ),
                ],
              )
            ] else ...[
               const SizedBox(height: 8),
               Align(
                 alignment: Alignment.centerRight,
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                   decoration: BoxDecoration(
                     color: req['status'] == 'approved' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(20),
                   ),
                   child: Text(
                     req['status'] == 'approved' ? 'Đã duyệt' : 'Đã từ chối',
                     style: TextStyle(
                       color: req['status'] == 'approved' ? Colors.green : Colors.red,
                       fontWeight: FontWeight.bold,
                       fontSize: 12
                     ),
                   ),
                 ),
               )
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _handleApprove(int id) async {
    final success = await ref.read(adminFinanceRepositoryProvider).approveWithdrawal(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã duyệt yêu cầu thành công'), backgroundColor: Colors.green));
      ref.invalidate(adminWithdrawalRequestsProvider); // Refresh lists
    } else {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xử lý thất bại'), backgroundColor: Colors.red));
    }
  }

  Future<void> _handleReject(int id) async {
    final noteController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối rút tiền'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(labelText: 'Lý do từ chối', hintText: 'Thông tin sai, nghi ngờ gian lận...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Từ chối')),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(adminFinanceRepositoryProvider).rejectWithdrawal(id, noteController.text);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã từ chối yêu cầu'), backgroundColor: Colors.orange));
        ref.invalidate(adminWithdrawalRequestsProvider);
      }
    }
  }
}
