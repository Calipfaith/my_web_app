import 'package:flutter/material.dart';

class ProductGridPage extends StatelessWidget {
  final products = [
    {"name": "Sneakers", "price": 120, "image": "assets/sneakers.png"},
    {"name": "Smartphone", "price": 999, "image": "assets/phone.png"},
    {"name": "Handbag", "price": 250, "image": "assets/handbag.png"},
    {"name": "Headphones", "price": 180, "image": "assets/headphones.png"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Products")),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              '/productDetail',
              arguments: product,
            ),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Image.asset(
                      product["image"] as String,   // ✅ cast to String
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    product["name"] as String,     // ✅ cast to String
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text("RM${product["price"]}"),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/productDetail',
                        arguments: product,
                      );
                    },
                    child: Text("View"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

