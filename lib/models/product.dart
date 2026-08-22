class Product {
  final String name;
  final double price;
  final String category;
  final String image;

  const Product({
    required this.name,
    required this.price,
    required this.category,
    required this.image,
  });
}

const products = [
  Product(
    name: 'Sneakers',
    price: 120,
    category: 'Men',
    image: 'sneakers',
  ),
  Product(
    name: 'Smartphone',
    price: 999,
    category: 'Electronics',
    image: 'smartphone',
  ),
  Product(
    name: 'Handbag',
    price: 250,
    category: 'Women',
    image: 'handbag',
  ),
  Product(
    name: 'Headphones',
    price: 180,
    category: 'Electronics',
    image: 'headphones',
  ),
];