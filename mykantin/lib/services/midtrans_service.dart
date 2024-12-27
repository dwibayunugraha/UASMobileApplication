// lib/services/midtrans_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';
import './transaction_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MidtransService {
  static const String baseUrl = 'https://app.sandbox.midtrans.com/snap/v1';
  static const String serverKey = 'SB-Mid-server-8055QNA56pEPx4G8aywKOWh4';
  static const String clientKey = 'SB-Mid-client-U73_o6sl1UvGKGvp';

  static final TransactionService _transactionService = TransactionService();

  static Future<Map<String, dynamic>> createTransaction({
    required String orderId,
    required int grossAmount,
    required String firstName,
    required String email,
  }) async {
    try {
      final String auth = base64Encode(utf8.encode('$serverKey:'));
      
      final response = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Basic $auth',
        },
        body: jsonEncode({
          'transaction_details': {
            'order_id': orderId,
            'gross_amount': grossAmount,
          },
          'customer_details': {
            'first_name': firstName,
            'email': email,
          },
          'enabled_payments': [
            'credit_card',
            'bca_va',
            'bni_va',
            'bri_va',
            'gopay',
            'shopeepay'
          ],
          'credit_card': {
            'secure': true
          }
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('Midtrans Response: $responseData'); // Untuk debugging

        // Simpan transaksi ke Realtime Database
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final transaction = Transaction(
            orderId: orderId,
            amount: grossAmount.toDouble(),
            status: 'pending',
            createdAt: DateTime.now(),
            paymentType: 'pending',
            userId: user.uid,
          );
          await _transactionService.saveTransaction(transaction);
        }

        return responseData;
      } else {
        print('Error Response: ${response.body}'); // Untuk debugging
        throw Exception('Failed to create transaction: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception during transaction creation: $e'); // Untuk debugging
      throw Exception('Network error: $e');
    }
  }

  static Future<String> checkTransactionStatus(String orderId) async {
    try {
      final String auth = base64Encode(utf8.encode('$serverKey:'));
      
      final response = await http.get(
        Uri.parse('https://api.sandbox.midtrans.com/v2/$orderId/status'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Basic $auth',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['transaction_status'];
        final paymentType = data['payment_type'];

        // Update status di Realtime Database
        await _transactionService.updateTransactionStatus(orderId, status);
        
        print('Transaction Status Response: $data'); // Untuk debugging
        return status;
      } else {
        print('Error checking status: ${response.body}'); // Untuk debugging
        throw Exception('Failed to check transaction status');
      }
    } catch (e) {
      print('Exception checking transaction status: $e'); // Untuk debugging
      throw Exception('Network error while checking status: $e');
    }
  }
}