import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../models/cart_item.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentMethod {
  final String name;
  final String image;
  final String description;

  PaymentMethod({
    required this.name,
    required this.image,
    required this.description,
  });
}

class PaymentPage extends StatefulWidget {
  final double totalAmount;
  final String notes;
  final List<CartItem> cartItems;

  const PaymentPage({
    Key? key,
    required this.totalAmount,
    required this.notes,
    required this.cartItems,
  }) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final formatCurrency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final List<PaymentMethod> paymentMethods = [
    PaymentMethod(
      name: 'Dana',
      image: 'assets/dana.png',
      description: 'Pay with Dana balance',
    ),
    PaymentMethod(
      name: 'Gopay',
      image: 'assets/gopay.png',
      description: 'Pay with Gopay balance',
    ),
    PaymentMethod(
      name: 'Bank Transfer',
      image: 'assets/bank.png',
      description: 'Pay via bank transfer',
    ),
  ];

  final DatabaseReference database = FirebaseDatabase.instance.ref();

  Future<String?> getAuthToken(String clientId, String clientSecret) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.dana.id/v1.0/auth/token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'client_id': clientId,
          'client_secret': clientSecret,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['access_token'];
      } else {
        print('Error getting token: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future<void> _processPayment(PaymentMethod method) async {
    if (method.name == 'Dana') {
      String clientId = 'your_client_id';
      String clientSecret = 'your_client_secret';

      String? token = await getAuthToken(clientId, clientSecret);

      if (token != null) {
        String orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';
        await database.child('payments/$orderId').set({
          'amount': widget.totalAmount,
          'order_id': orderId,
          'status': 'pending',
          'notes': widget.notes,
        });

        try {
          String redirectUrl = await _getPaymentUrlFromBackend(orderId, token);

          if (await canLaunchUrl(Uri.parse(redirectUrl))) {
            await launchUrl(Uri.parse(redirectUrl));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tidak dapat membuka aplikasi DANA')),
            );
            throw 'Could not launch $redirectUrl';
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Terjadi kesalahan: $e')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mendapatkan token autentikasi')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Metode pembayaran ${method.name} belum didukung')),
      );
    }
  }

  Future<String> _getPaymentUrlFromBackend(String orderId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.150:3000/create-payment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'amount': widget.totalAmount,
          'order_id': orderId,
          'description': widget.notes,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['redirect_url'];
      } else {
        throw Exception('Gagal membuat URL pembayaran');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat menghubungi server: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: paymentMethods.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final method = paymentMethods[index];
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _processPayment(method),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              method.image,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  method.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  method.description,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total Payment',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatCurrency.format(widget.totalAmount),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Payment confirmation logic...
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Confirm Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
