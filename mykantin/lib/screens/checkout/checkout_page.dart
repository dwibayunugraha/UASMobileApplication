import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:html' as html;
import '../../models/cart_item.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/midtrans_service.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:ui_web' as ui_web;

class CheckoutPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final double totalAmount;

  const CheckoutPage({
    Key? key,
    required this.cartItems,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _notesController = TextEditingController();
  final formatCurrency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'IDR ',
    decimalDigits: 0,
  );
  bool _isProcessing = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    if (_isProcessing) return; // Prevent double submission
    
    setState(() => _isProcessing = true);
    
    try {
      // Validasi jumlah minimum
      if (widget.totalAmount < 10000) {
        throw Exception('Minimum transaction amount is IDR 10,000');
      }

      // Check if user is logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Please login to continue');
      }

      // Create order ID and transaction
      final orderId = 'ORDER-${DateTime.now().millisecondsSinceEpoch}-${user.uid.substring(0, 5)}';
      print('Creating transaction with order ID: $orderId'); // Untuk debugging

      final transactionData = await MidtransService.createTransaction(
        orderId: orderId,
        grossAmount: widget.totalAmount.round(),
        firstName: user.displayName ?? 'Customer',
        email: user.email ?? '',
      );

      if (transactionData['redirect_url'] == null) {
        throw Exception('Failed to get payment URL');
      }

      print('Got redirect URL: ${transactionData['redirect_url']}'); // Untuk debugging

      // Show payment page
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewPage(transactionData['redirect_url']),
        ),
      );

      // Handle payment result
      if (result == true) {
        print('Checking transaction status for order: $orderId'); // Untuk debugging
        final status = await MidtransService.checkTransactionStatus(orderId);
        
        if (status == 'settlement' || status == 'capture' || status == 'success') {
          // Payment successful
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment successful!')),
          );
          
          // TODO: Add your order processing logic here
          // For example: save to database, clear cart, etc.
          
          Navigator.of(context).pop(true); // Return success to previous screen
        } else {
          throw Exception('Payment not completed. Status: $status');
        }
      } else {
        throw Exception('Payment cancelled or failed');
      }
    } catch (e) {
      print('Payment error: $e'); // Untuk debugging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...widget.cartItems.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.image,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      formatCurrency.format(item.price),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text('×${item.quantity}'),
                            ],
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Notes Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            hintText: 'Add notes to your order...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Price Details
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              formatCurrency.format(widget.totalAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handlePayment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.red[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Proceed to Payment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WebViewPage extends StatelessWidget {
  final String url;

  const WebViewPage(this.url, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // For web platform
      return Scaffold(
        appBar: AppBar(title: const Text('Midtrans Payment')),
        body: SizedBox.expand(
          child: IframeElement(url: url),
        ),
      );
    } else {
      // For mobile platform
      return Scaffold(
        appBar: AppBar(title: const Text('Midtrans Payment')),
        body: WebViewWidget(
          controller: WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadRequest(Uri.parse(url)),
        ),
      );
    }
  }
}

// Custom widget for web iframe
class IframeElement extends StatelessWidget {
  final String url;

  const IframeElement({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create unique viewID for iframe
    final String viewId = 'iframe-${DateTime.now().millisecondsSinceEpoch}';
    
    // Register view factory dengan ui_web yang benar
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = url
        ..style.border = 'none'
        ..style.height = '100%'
        ..style.width = '100%';
      return iframe;
    });

    return HtmlElementView(viewType: viewId);
  }
}