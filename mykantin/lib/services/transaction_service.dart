import 'package:firebase_database/firebase_database.dart' as fbdb;
import '../models/transaction.dart' as mykn;

class TransactionService {
  final fbdb.DatabaseReference _database = fbdb.FirebaseDatabase.instance.ref();

  // Menyimpan transaksi baru
  Future<void> saveTransaction(mykn.Transaction transaction) async {
    try {
      await _database
          .child('transactions')
          .child(transaction.orderId)
          .set(transaction.toMap());
    } catch (e) {
      print('Error saving transaction: $e');
      throw Exception('Failed to save transaction');
    }
  }

  // Mendapatkan transaksi berdasarkan orderId
  Future<mykn.Transaction?> getTransaction(String orderId) async {
    try {
      final snapshot = await _database
          .child('transactions')
          .child(orderId)
          .get();
      
      if (snapshot.exists) {
        return mykn.Transaction.fromMap(
          Map<String, dynamic>.from(snapshot.value as Map),
        );
      }
      return null;
    } catch (e) {
      print('Error getting transaction: $e');
      throw Exception('Failed to get transaction');
    }
  }

  // Mendapatkan semua transaksi user
  Future<List<mykn.Transaction>> getUserTransactions(String userId) async {
    try {
      final snapshot = await _database
          .child('transactions')
          .orderByChild('userId')
          .equalTo(userId)
          .get();
      
      if (!snapshot.exists) {
        return [];
      }

      final transactionsMap = Map<String, dynamic>.from(
        snapshot.value as Map,
      );

      return transactionsMap.values
          .map((data) => mykn.Transaction.fromMap(Map<String, dynamic>.from(data)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort by date desc
    } catch (e) {
      print('Error getting user transactions: $e');
      throw Exception('Failed to get user transactions');
    }
  }

  // Update status transaksi
  Future<void> updateTransactionStatus(String orderId, String status) async {
    try {
      await _database
          .child('transactions')
          .child(orderId)
          .update({'status': status});
    } catch (e) {
      print('Error updating transaction status: $e');
      throw Exception('Failed to update transaction status');
    }
  }

  // Stream untuk mendengarkan perubahan status transaksi
  Stream<String?> watchTransactionStatus(String orderId) {
    return _database
        .child('transactions')
        .child(orderId)
        .child('status')
        .onValue
        .map((event) => event.snapshot.value as String?);
  }
}
