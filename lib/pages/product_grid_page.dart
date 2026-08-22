import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/product_image.dart';

class ProductGridPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final category = arguments is Map ? arguments['category'] as String? : null;
    final visibleProducts = category == null
        ? products
        : products.where((product) => product.category == category).toList();

    return Scaffold(
      appBar: AppBar(title: Text(category == null ? "Products" : category)),
      body: visibleProducts.isEmpty
          ? Center(child: Text("No products found"))
          : GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: visibleProducts.length,
        itemBuilder: (context, index) {
          final product = visibleProducts[index];
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
                    child: ProductImage(name: product.name),
                  ),
                  SizedBox(height: 8),
                  Text(
                    product.name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text("RM${product.price.toStringAsFixed(0)}"),
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

