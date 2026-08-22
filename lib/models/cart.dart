// lib/models/cart.dart
class CartItem {
  final String name;
  final double price;
  final String image;
  int quantity;

  CartItem({
    required this.name,
    required this.price,
    required this.image,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'image': image,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      image: map['image'] as String,
      quantity: (map['quantity'] as num).toInt(),
    );
  }
}
