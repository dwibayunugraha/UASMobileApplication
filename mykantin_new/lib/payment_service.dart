import 'dart:convert';
import 'package:http/http.dart' as http;

// URL untuk API Authorization dan Pembayaran
const String authUrl = 'https://api.dana.id/v1.0/auth/token'; // URL token authorization
const String paymentUrl = 'https://api.dana.id/v1.0/emoney/otc-cashout.htm'; // URL pembayaran

// Fungsi untuk mendapatkan JWT Token
Future<String?> getAuthToken(String clientId, String clientSecret) async {
  try {
    final response = await http.post(
      Uri.parse(authUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'client_id': clientId,
        'client_secret': clientSecret,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['access_token']; // Ambil JWT token dari response
    } else {
      print('Error getting token: ${response.body}');
      return null;
    }
  } catch (e) {
    print('Error: $e');
    return null;
  }
}

// Fungsi untuk membuat pembayaran menggunakan token
Future<void> createPayment(String token, String partnerReferenceNo, String customerNumber, String otp, double amount) async {
  try {
    final response = await http.post(
      Uri.parse(paymentUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'X-TIMESTAMP': DateTime.now().toIso8601String(),
      },
      body: json.encode({
        'partnerReferenceNo': partnerReferenceNo,
        'customerNumber': customerNumber,
        'otp': otp,
        'amount': {
          'currency': 'IDR',
          'value': amount.toStringAsFixed(2), // Mengatur jumlah dalam format yang benar
        },
        'additionalInfo': {
          'extensionInfo': {
            'postId': 'Q07275',
            'storeId': '14054',
            'phoneNumber': customerNumber,
          }
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Payment Successful: ${data['responseMessage']}');
    } else {
      print('Payment Failed: ${response.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}

