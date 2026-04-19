import 'package:doantotnghiep/core/theme/edu_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TutorTransactionHistoryScreen extends StatelessWidget {
  const TutorTransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // Mock data for history
    final transactions = [
      {
        'id': 'TX1001',
        'type': 'deposit',
        'amount': 500000.0,
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'description': 'Học phí lớp Toán 12 (Nguyễn Văn A)',
        'status': 'completed',
      },
      {
        'id': 'TX1002',
        'type': 'withdrawal',
        'amount': -2000000.0,
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'description': 'Rút tiền về Vietcombank (****1234)',
        'status': 'processing',
      },
      {
        'id': 'TX1003',
        'type': 'deposit',
        'amount': 300000.0,
        'date': DateTime.now().subtract(const Duration(days: 7)),
        'description': 'Học phí lớp Lý 10',
        'status': 'completed',
      },
       {
        'id': 'TX1004',
        'type': 'withdrawal',
        'amount': -500000.0,
        'date': DateTime.now().subtract(const Duration(days: 15)),
        'description': 'Rút tiền ví Momo',
        'status': 'completed',
      },
    ];

    return Scaffold(
      backgroundColor: EduTheme.background,
      appBar: AppBar(
        title: const Text('Lịch sử giao dịch', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final tx = transactions[index];
          final isDeposit = tx['type'] == 'deposit';
          final amount = tx['amount'] as double;
          final date = tx['date'] as DateTime;
          final status = tx['status'] as String;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDeposit ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isDeposit ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx['description'].toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(date),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${amount > 0 ? '+' : ''}${currency.format(amount)}',
                      style: TextStyle(
                        color: isDeposit ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: status == 'completed' ? Colors.green[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: status == 'completed' ? Colors.green : Colors.orange,
                          width: 0.5,
                        )
                      ),
                      child: Text(
                        status == 'completed' ? 'Thành công' : 'Đang xử lý',
                        style: TextStyle(
                          color: status == 'completed' ? Colors.green : Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
