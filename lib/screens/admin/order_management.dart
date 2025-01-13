import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class OrderManagementPage extends StatefulWidget {
  const OrderManagementPage({super.key});

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> {
  final DatabaseReference _orderDatabase = FirebaseDatabase.instance.ref().child('orders');
  final DatabaseReference _userDatabase = FirebaseDatabase.instance.ref().child('users');
  Map<String, dynamic> _users = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final snapshot = await _userDatabase.get();
    if (snapshot.value != null) {
      setState(() {
        _users = Map<String, dynamic>.from(snapshot.value as Map);
      });
    }
  }

  String _getCustomerName(String? userId) {
    if (userId == null || !_users.containsKey(userId)) {
      return 'Unknown';
    }
    return _users[userId]['name'] ?? 'Unknown';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'processing':
        return 'Diproses';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
      ),
      body: StreamBuilder(
        stream: _orderDatabase.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada pesanan',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          Map<dynamic, dynamic> orders = Map<dynamic, dynamic>.from(
              snapshot.data!.snapshot.value as Map);

          List<MapEntry<dynamic, dynamic>> orderList = orders.entries.toList();
          orderList.sort((a, b) => DateTime.parse(b.value['orderDate'])
              .compareTo(DateTime.parse(a.value['orderDate'])));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orderList.length,
            itemBuilder: (context, index) {
              final order = orderList[index].value;
              final orderId = orderList[index].key;
              final orderDate = DateTime.parse(order['orderDate']);
              final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(orderDate);
              final customerName = _getCustomerName(order['userId']);

              // Calculate total from items
              double total = 0;
              List<dynamic> items = order['items'] as List<dynamic>;
              for (var item in items) {
                total += (item['price'] as num) * (item['quantity'] as num);
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (String status) async {
                              await _orderDatabase.child(orderId).update({
                                'status': status
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Status pesanan berhasil diupdate'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem(
                                value: 'pending',
                                child: Text('Menunggu'),
                              ),
                              const PopupMenuItem(
                                value: 'processing',
                                child: Text('Diproses'),
                              ),
                              const PopupMenuItem(
                                value: 'completed',
                                child: Text('Selesai'),
                              ),
                              const PopupMenuItem(
                                value: 'cancelled',
                                child: Text('Dibatalkan'),
                              ),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order['status'] ?? 'pending').withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusText(order['status'] ?? 'pending'),
                                style: TextStyle(
                                  color: _getStatusColor(order['status'] ?? 'pending'),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Order #${orderId.toString().substring(0, 8)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Customer: $customerName',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Table: ${order['tableNumber'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const Divider(height: 24),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: (order['items'] as List).length,
                        itemBuilder: (context, itemIndex) {
                          final item = order['items'][itemIndex];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item['quantity']}x ${item['name']}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Text(
                                  'Rp ${NumberFormat('#,###').format(item['price'] * item['quantity'])}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Rp ${NumberFormat('#,###').format(total)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}