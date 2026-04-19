import 'package:cached_network_image/cached_network_image.dart';
import 'package:doantotnghiep/features/auth/data/auth_repository.dart';
import 'package:doantotnghiep/features/wallet/data/wallet_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doantotnghiep/features/auth/data/auth_repository.dart';
import 'package:doantotnghiep/features/wallet/data/wallet_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DepositScreen extends ConsumerStatefulWidget {
  final double? initialAmount;
  const DepositScreen({super.key, this.initialAmount});

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  final _amountController = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  
  String? _qrUrl;
  String? _transferContent;
  
  // Config
  final String bankId = 'MB'; 
  final String accountNo = '0334996903'; 
  final String accountName = 'HE THONG GIA SU'; 

  final List<double> _quickAmounts = [50000, 100000, 200000, 500000];

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toInt().toString();
      _processDeposit();
    }
  }

  void _processDeposit() {
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountText);
    final user = ref.read(authRepositoryProvider).currentUser;

    if (amount == null || amount < 10000 || user == null) {
      return;
    }

    final content = "NAP ${user.id}";
    _showFakeBankApp(amount, content);
  }

  void _onAmountChanged(String value) {
  }

  void _selectAmount(double amount) {
    _amountController.text = amount.toInt().toString();
    _processDeposit();
  }

  void _showFakeBankApp(double amount, String content) {
     showModalBottomSheet(
       context: context,
       isScrollControlled: true,
       backgroundColor: Colors.transparent,
       builder: (modalContext) => _FakeBankApp(
         amount: amount, 
         content: content, 
         onConfirm: () async {
            final user = ref.read(authRepositoryProvider).currentUser;
            if (user != null) {
               final idInt = int.tryParse(user.id);
               if (idInt != null) {
                  Navigator.pop(modalContext);

                  if (!mounted) return;
                  showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                  await Future.delayed(const Duration(seconds: 2));
                  
                  await ref.read(walletProvider.notifier).simulateDeposit(amount, idInt);
                  
                  if (mounted) {
                     Navigator.of(context, rootNavigator: true).pop();
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nạp tiền thành công!')));
                     Navigator.of(context).pop();
                  }
               }
            }
         }
       )
     );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text('Nạp tiền vào ví'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,5))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nhập số tiền nạp', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                    decoration: const InputDecoration(
                      hintText: '0',
                      suffixText: 'VNĐ',
                      border: InputBorder.none,
                      isDense: true
                    ),
                    onChanged: (val) {
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: _quickAmounts.map((amt) => ChoiceChip(
                      label: Text(currencyFormat.format(amt)),
                      selected: _amountController.text == amt.toInt().toString(),
                      onSelected: (selected) {
                        if (selected) _selectAmount(amt);
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                       onPressed: _processDeposit, 
                       child: const Text('Nạp tiền')
                    ),
                  )
                ],
              ),
            ),

            // QR Card block removed as requested

          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
     return Row(
       mainAxisAlignment: MainAxisAlignment.spaceBetween,
       children: [
         Text(label, style: const TextStyle(color: Colors.grey)),
         Expanded(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14))),
       ],
     );
  }

  Widget _buildCopyRow(BuildContext context, String label, String value) {
     return Row(
       mainAxisAlignment: MainAxisAlignment.spaceBetween,
       children: [
         Text(label, style: const TextStyle(color: Colors.grey)),
         Expanded(
           child: Row(
             mainAxisAlignment: MainAxisAlignment.end,
             children: [
               Flexible(child: Text(value, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
               const SizedBox(width: 8),
               InkWell(
                 onTap: () {
                   if (value.isNotEmpty) {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép')));
                   }
                 },
                 child: const Icon(Icons.copy, size: 16, color: Colors.blue),
               )
             ],
           ),
         )
       ],
     );
  }
}

class _FakeBankApp extends StatelessWidget {
   final double amount;
   final String content;
   final VoidCallback onConfirm;
   
   const _FakeBankApp({required this.amount, required this.content, required this.onConfirm});

   @override
   Widget build(BuildContext context) {
      final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
      return Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF1E3A8A), // Dark Blue like MB
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
             // Fake StatusBar
             const SizedBox(height: 10),
             Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)))),
             const SizedBox(height: 20),
             const Text('MB BANK SIMULATOR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
             const SizedBox(height: 30),
             
             Expanded(
               child: Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(24),
                 decoration: const BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      const Text('Xác nhận chuyển tiền', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 30),
                      
                      _buildField('Tài khoản nguồn', 'NGUYEN VAN A - 88888888'),
                      const Divider(),
                      _buildField('Tài khoản thụ hưởng', 'HE THONG GIA SU - 0334996903'),
                      const Divider(),
                      _buildField('Ngân hàng', 'MB BANK'),
                      const Divider(),
                      _buildField('Số tiền', currencyFormat.format(amount), color: Colors.blue, isBold: true),
                      const Divider(),
                      _buildField('Nội dung', content),
                      const SizedBox(height: 10),
                      const Text('Phí giao dịch: 0đ', style: TextStyle(color: Colors.grey)),
                      
                      const Spacer(),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: onConfirm,
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
                          child: const Text('XÁC NHẬN CHUYỂN NGAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 20),
                   ],
                 ),
               ),
             )
          ],
        ),
      );
   }

   Widget _buildField(String label, String value, {Color? color, bool isBold = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            const SizedBox(width: 10),
            Expanded(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 15, color: color ?? Colors.black))),
          ],
        ),
      );
   }
}
