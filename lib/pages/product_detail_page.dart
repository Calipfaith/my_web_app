import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../widgets/product_image.dart';

class ProductDetailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Product data passed from ProductGridPage
    final product = ModalRoute.of(context)!.settings.arguments as Product;

    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ProductImage(name: product.name, height: 200),
            ),
            SizedBox(height: 16),
            Text(
              product.name,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text("RM${product.price.toStringAsFixed(0)}", style: TextStyle(fontSize: 18)),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.verified, color: Colors.green),
                SizedBox(width: 8),
                Text("Authenticity Verified"),
              ],
            ),
            SizedBox(height: 16),
            Text(
              "Product Description: High-quality ${product.name} with warranty.",
            ),
            SizedBox(height: 16),
            Text("Reviews:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("⭐️⭐️⭐️⭐️☆ - Great product, fast delivery."),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // ✅ Use CartProvider to add item globally
                  final cart = Provider.of<CartProvider>(context, listen: false);
                  cart.addItem(CartItem(
                    name: product.name,
                    price: product.price,
                    image: product.image,
                  ));
                  Navigator.pushNamed(context, '/cart');
                },
                child: Text("Add to Cart"),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
