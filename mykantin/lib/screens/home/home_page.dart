import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '/models/cart_item.dart';
import '../cart/cart_page.dart';
import '../order/order_page.dart'; // Make sure to create this
import '../profile/profile_page.dart'; // Make sure to create this
import 'package:intl/intl.dart'; // Add this for number formatting

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  int _selectedCategory = 0;
  List<CartItem> cartItems = [];
  List<Map<String, dynamic>> _menuItems = [];
  final formatCurrency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'IDR ',
    decimalDigits: 0,
  );

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Makanan', 'icon': Icons.restaurant},
    {'name': 'Minuman', 'icon': Icons.local_drink},
    {'name': 'Snack', 'icon': Icons.cookie},
  ];

  // Fungsi untuk mengambil data menu dari Firebase Realtime Database
  Future<void> _fetchMenuItems() async {
    final databaseReference = FirebaseDatabase.instance.ref('menu_items');
    try {
      final snapshot = await databaseReference.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _menuItems = data.values
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        });
      } else {
        print('Data not found');
      }
    } catch (e) {
      print('Failed to load data: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchMenuItems();
  }

void _addToCart(Map<String, dynamic> item) {
  setState(() {
    var existingItemIndex = cartItems.indexWhere(
      (element) => element.name == item['name'],
    );

    if (existingItemIndex == -1) {
      // Item belum ada di keranjang
      cartItems.add(CartItem(
        id: item.containsKey('id') ? item['id'] : 'no-id', // Pastikan id tidak null
        name: item.containsKey('name') ? item['name'] : 'No Name', // Pastikan name tidak null
        price: item.containsKey('price') ? item['price'].toDouble() : 0.0, // Pastikan price tidak null
        image: item.containsKey('image') ? item['image'] : '', // Pastikan image tidak null
        quantity: 1,
      ));
    } else {
      // Item sudah ada, tambah quantity menggunakan metode updateQuantity
      cartItems[existingItemIndex].updateQuantity(
        cartItems[existingItemIndex].quantity + 1,
      );
    }
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('${item['name']} ditambahkan ke keranjang'),
      duration: const Duration(seconds: 1),
      action: SnackBarAction(
        label: 'Lihat',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CartPage(
                cartItems: cartItems,
                onUpdateQuantity: (item) {
                  setState(() {});
                },
                onRemoveItem: (item) {
                  setState(() {
                    cartItems.remove(item);
                  });
                },
              ),
            ),
          );
        },
      ),
    ),
  );
}



  Widget _buildHomePage() {
    final filteredItems = _menuItems.where((item) {
      if (_selectedCategory == 0) return item['category'] == 'Makanan';
      if (_selectedCategory == 1) return item['category'] == 'Minuman';
      if (_selectedCategory == 2) return item['category'] == 'Snack';
      return true;
    }).toList();

    return Column(
      children: [
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = index;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedCategory == index
                        ? Colors.red[700]
                        : Colors.grey[200],
                    foregroundColor: _selectedCategory == index
                        ? Colors.white
                        : Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: Icon(_categories[index]['icon']),
                  label: Text(_categories[index]['name']),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _menuItems.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final formattedPrice = formatCurrency.format(filteredItems[index]['price']);
                    return GestureDetector(
                      onTap: () => _showItemDetail(context, filteredItems[index]),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: AspectRatio(
                                aspectRatio: 1.2,
                                child: Image.network(
                                  filteredItems[index]['image'],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              filteredItems[index]['name'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              formattedPrice,
                                              style: TextStyle(
                                                color: Colors.red[700],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      FloatingActionButton.small(
                                        onPressed: () => _addToCart(filteredItems[index]),
                                        backgroundColor: Colors.red[700],
                                        child: const Icon(Icons.add, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.amber[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        filteredItems[index]['rating'].toString(),
                                        style: const TextStyle(
                                          fontSize: 12,
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
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showItemDetail(BuildContext context, Map<String, dynamic> item) {
    final formattedPrice = formatCurrency.format(item['price']);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item['image'],
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item['name'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 4),
                  Text(
                    item['rating'].toString(),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formattedPrice,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      item['description'] ?? 'Tidak ada deskripsi',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    _addToCart(item);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Add to Cart',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // List of pages for bottom navigation
    final List<Widget> pages = [
      _buildHomePage(),
      const OrderPage(), // Create this page
      const ProfilePage(), // Create this page
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
              },
              child: Text(
                'MyKantin',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            Stack(
              children: [
                IconButton(
  icon: const Icon(Icons.shopping_bag_outlined),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(
          cartItems: cartItems,
          onUpdateQuantity: (item) {
            setState(() {});
          },
          onRemoveItem: (item) {
            setState(() {
              cartItems.remove(item);
            });
          },
        ),
      ),
    );
  },
  color: Colors.black,
),
                if (cartItems.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        cartItems.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      body: pages[_selectedIndex], // This will show the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Order',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Colors.red[700],
      ),
    );
  }
}