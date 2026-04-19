import 'package:doantotnghiep/features/auth/data/auth_repository.dart';
import 'package:doantotnghiep/features/wallet/data/wallet_provider.dart';
import 'package:doantotnghiep/features/wallet/presentation/deposit_screen.dart';
import 'package:doantotnghiep/features/wallet/presentation/pin_change_screen.dart';
import 'package:doantotnghiep/features/wallet/presentation/pin_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final isTutor = ref.watch(authRepositoryProvider).currentUser?.role == 'tutor' || 
                    ref.watch(authRepositoryProvider).currentUser?.tutorProfile != null;

    return Scaffold(
      appBar: isTutor ? _buildTutorAppBar(context) : AppBar(title: const Text('Ví của tôi')),
      body: walletAsync.when(
        data: (walletState) {
          final balance = walletState.balance;
          final transactions = walletState.transactions;

          return RefreshIndicator(
            onRefresh: () async {
              return ref.refresh(walletProvider.future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                   // ... (Content)
                  Container(
                    margin: const EdgeInsets.all(16),
                    // ... content
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Theme.of(context).primaryColor, Colors.indigo],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
                    ),
                    child: Column(
                      children: [
                        const Text('Số dư khả dụng', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat.format(balance),
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(context, Icons.add, 'Nạp tiền', () {
                               // Navigate to Deposit Screen
                               Navigator.push(context, MaterialPageRoute(builder: (_) => const DepositScreen()));
                            }),
                            _buildActionButton(context, Icons.arrow_upward, 'Rút tiền', () {
                               final user = ref.read(authRepositoryProvider).currentUser;
                               // Restriction: Students can only withdraw on the 15th
                               if (user?.role == 'student' && DateTime.now().day != 15) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text('Học viên chỉ được rút tiền vào ngày 15 hàng tháng'),
                                    backgroundColor: Colors.orange,
                                  ));
                                  return;
                               }
                               _showWithdrawDialog(context, ref, balance);
                            }),
                            _buildActionButton(
                              context, 
                              Icons.lock, 
                              walletState.hasPaymentPin ? 'Đổi PIN' : 'Tạo PIN', 
                              () {
                                 if (walletState.hasPaymentPin) {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PinChangeScreen()));
                                 } else {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PinSetupScreen()));
                                 }
                              }
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Transactions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Lịch sử giao dịch', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (transactions.isEmpty)
                    const Padding(padding: EdgeInsets.all(16), child: Text("Chưa có giao dịch nào."))
                  else
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: transactions.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        // Determine Credit/Debit based on backend types
                        final isCredit = tx.type == 'deposit' || tx.type == 'earning' || tx.type == 'refund';
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCredit ? Colors.green[100] : Colors.red[100],
                            child: Icon(
                              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isCredit ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(tx.title), // Backend description mapped to title
                          subtitle: Text(dateFormat.format(tx.date)),
                          trailing: Text(
                            '${isCredit ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                            style: TextStyle(
                              color: isCredit ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi tải ví: $err')),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(30)),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  void _showDepositDialog(BuildContext context, WidgetRef ref) {
      final controller = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nạp tiền Demo'),
          content: TextField(
             controller: controller,
             keyboardType: TextInputType.number,
             decoration: const InputDecoration(labelText: 'Số tiền (VNĐ)', hintText: 'VD: 500000'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            FilledButton(
               onPressed: () {
                 final amount = double.tryParse(controller.text);
                 if (amount != null && amount >= 10000) {
                    ref.read(walletProvider.notifier).deposit(amount);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang xử lý nạp tiền...')));
                 }
               }, 
               child: const Text('Nạp ngay')
            ),
          ],
        ),
      );
  }

  void _showWithdrawDialog(BuildContext context, WidgetRef ref, double currentBalance) {
    final amountController = TextEditingController();
    final bankNameController = TextEditingController();
    final accountNumberController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rút tiền về ngân hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 12.0),
              child: Text(
                '*Lưu ý: Học viên chỉ được rút tiền duy nhất vào ngày 15 hàng tháng.',
                style: TextStyle(color: Colors.orange, fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số tiền rút (VNĐ)',
                hintText: 'Tối thiểu 50,000',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bankNameController,
              decoration: const InputDecoration(labelText: 'Tên ngân hàng', hintText: 'VD: Vietcombank'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: accountNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số tài khoản'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount < 50000) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số tiền tối thiểu là 50,000đ')));
                 return;
              }
              if (amount > currentBalance) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số dư không đủ')));
                 return;
              }
              if (bankNameController.text.isEmpty || accountNumberController.text.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập thông tin ngân hàng')));
                 return;
              }

              ref.read(walletProvider.notifier).withdraw(amount, bankNameController.text, accountNumberController.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang xử lý rút tiền...')));
            },
            child: const Text('Rút tiền'),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTutorAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFFA855F7)], // EduTheme.primary, EduTheme.purple
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Ví của tôi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
      ),
    );
  }
}
