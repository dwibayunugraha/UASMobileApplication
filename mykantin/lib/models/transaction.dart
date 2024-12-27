// lib/models/transaction.dart
class Transaction {
  final String orderId;
  final double amount;
  final String status;
  final DateTime createdAt;
  final String paymentType;
  final String userId;

  Transaction({
    required this.orderId,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.paymentType,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'amount': amount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'paymentType': paymentType,
      'userId': userId,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      orderId: map['orderId'],
      amount: map['amount'],
      status: map['status'],
      createdAt: DateTime.parse(map['createdAt']),
      paymentType: map['paymentType'],
      userId: map['userId'],
    );
  }
}