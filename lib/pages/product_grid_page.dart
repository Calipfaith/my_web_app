import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/catalog_service.dart';
import '../widgets/product_image.dart';

class ProductGridPage extends StatefulWidget {
  const ProductGridPage({super.key});

  @override
  State<ProductGridPage> createState() => _ProductGridPageState();
}

class _ProductGridPageState extends State<ProductGridPage> {
  final catalogService = CatalogService();
  late final Future<List<Product>> productsFuture;
  String searchQuery = '';
  String sortOrder = 'Recommended';

  @override
  void initState() {
    super.initState();
    productsFuture = catalogService.getProducts();
  }

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final category = arguments is Map ? arguments['category'] as String? : null;
    return Scaffold(
      appBar: AppBar(title: Text(category == null ? "Products" : category)),
      body: FutureBuilder<List<Product>>(
        future: productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load products'));
          }

          var visibleProducts = category == null
              ? snapshot.data ?? <Product>[]
              : (snapshot.data ?? <Product>[])
                  .where((product) => product.category == category)
                  .toList();
          visibleProducts = visibleProducts
              .where((product) =>
                  product.name.toLowerCase().contains(searchQuery))
              .toList();
          if (sortOrder == 'Price: Low to high') {
            visibleProducts.sort((a, b) => a.price.compareTo(b.price));
          } else if (sortOrder == 'Price: High to low') {
            visibleProducts.sort((a, b) => b.price.compareTo(a.price));
          }

          return Column(
            children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search products',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() {
                searchQuery = value.trim().toLowerCase();
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              initialValue: sortOrder,
              decoration: const InputDecoration(labelText: 'Sort by'),
              items: const [
                DropdownMenuItem(value: 'Recommended', child: Text('Recommended')),
                DropdownMenuItem(value: 'Price: Low to high', child: Text('Price: Low to high')),
                DropdownMenuItem(value: 'Price: High to low', child: Text('Price: High to low')),
              ],
              onChanged: (value) => setState(() => sortOrder = value!),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: visibleProducts.isEmpty
                ? const Center(child: Text("No products found"))
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
          ),
            ],
          );
        },
      ),
    );
  }
}

