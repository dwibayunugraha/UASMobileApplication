class CartItem {
  final String id;
  final String name;
  final int price;
  int quantity; // Ubah dari final int quantity menjadi int quantity
  final String image;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.image,
  });

  double get total => price * quantity.toDouble();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'image': image,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      quantity: map['quantity'],
      image: map['image'],
    );
  }

  void updateQuantity(int newQuantity) {
    quantity = newQuantity;
  }
}
