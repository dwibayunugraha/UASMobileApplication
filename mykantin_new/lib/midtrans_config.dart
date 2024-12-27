import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MidtransConfig {
  static const String _serverKey = 'SB-Mid-server-8055QNA56pEPx4G8aywKOWh4';
  static const String _baseUrl = 'https://app.sandbox.midtrans.com/snap/v1/transactions';

  static Future<String?> getSnapToken({
    required String orderId,
    required double amount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required BuildContext context,
  }) async {
    try {
      // Encode server key
      final String auth = base64.encode(utf8.encode('$_serverKey:'));

      // Request body
      final Map<String, dynamic> requestBody = {
        'transaction_details': {
          'order_id': orderId,
          'gross_amount': amount.toInt(),
        },
        'customer_details': {
          'first_name': customerName,
          'email': customerEmail,
          'phone': customerPhone,
        },
        'credit_card': {
          'secure': true
        },
      };

      print('Making request to: $_baseUrl');
      print('Request body: ${jsonEncode(requestBody)}');

      // Send POST request ke server lokal
      final response = await http.post(
        Uri.parse('http://192.168.1.7:3000/get-snap-token'),  // URL server lokal
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Basic $auth',
        },
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {  // Pastikan status code 201, bukan 200
        final data = json.decode(response.body);
        final token = data['token'];
        final redirectUrl = data['redirect_url'];  // Periksa apakah URL ini ada

        if (token != null) {
          if (kIsWeb) {
            // Open Snap URL in a new tab for web
            await launchUrl(Uri.parse(redirectUrl), mode: LaunchMode.externalApplication);
          } else {
            // Open Snap token page in WebView for Android
            openPaymentPage(context, token);
          }
          return token;
        }
      } else {
        throw Exception('Failed to get Snap Token. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting Snap token: $e');
      rethrow;
    }
    return null;
  }

  static void openPaymentPage(BuildContext context, String snapToken) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentWebView(snapToken: snapToken),
      ),
    );
  }
}

class PaymentWebView extends StatefulWidget {
  final String snapToken;

  const PaymentWebView({Key? key, required this.snapToken}) : super(key: key);

  @override
  _PaymentWebViewState createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize the WebView controller
    _controller = WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted);
    _controller.loadRequest(Uri.parse('https://app.sandbox.midtrans.com/snap/v1/transactions/${widget.snapToken}'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
