import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/catalog_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/product_card.dart';

class ProductGridPage extends StatefulWidget {
  final CatalogService catalogService;

  const ProductGridPage({super.key, required this.catalogService});

  @override
  State<ProductGridPage> createState() => _ProductGridPageState();
}

class _ProductGridPageState extends State<ProductGridPage> {
  late final Future<List<Product>> productsFuture;
  String searchQuery = '';
  String sortOrder = 'Recommended';

  @override
  void initState() {
    super.initState();
    productsFuture = widget.catalogService.getProducts();
  }

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final category = arguments is Map ? arguments['category'] as String? : null;
    return AppScaffold(
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
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text(category == null ? 'All products' : category, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Search products', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
                  onChanged: (value) => setState(() => searchQuery = value.trim().toLowerCase()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
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
              visibleProducts.isEmpty
                ? const Center(child: Text("No products found"))
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : MediaQuery.of(context).size.width >= 500 ? 2 : 1, childAspectRatio: .78, crossAxisSpacing: 16, mainAxisSpacing: 16),
                    itemCount: visibleProducts.length,
                    itemBuilder: (context, index) => ProductCard(product: visibleProducts[index], index: index, onTap: () => Navigator.pushNamed(context, '/productDetail', arguments: visibleProducts[index])),
                ),
            ],
          );
        },
      ),
    );
  }
}

