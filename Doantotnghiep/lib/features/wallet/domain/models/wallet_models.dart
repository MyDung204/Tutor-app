class WalletTransaction {
  final String id;
  final double amount;
  final String type; // deposit, payment...
  final String title;
  final String status;
  final DateTime date;

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.title,
    required this.status,
    required this.date,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'].toString(),
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      type: json['type'] ?? 'payment',
      title: json['description'] ?? 'Giao dịch',
      status: json['status'] ?? 'pending',
      date: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

class WalletState {
  final double balance;
  final bool hasPaymentPin;
  final List<WalletTransaction> transactions;

  WalletState({
    this.balance = 0, 
    this.hasPaymentPin = false, 
    this.transactions = const []
  });
}
