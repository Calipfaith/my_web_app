import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/app_button.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/product_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const categories = ['All', 'Electronics', 'Fashion', 'Home', 'Beauty'];
  String selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;
    final visibleProducts = selectedCategory == 'All'
        ? products
        : products.where((product) => product.category == selectedCategory).toList();

    return AppScaffold(
      body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeroSection(isWide: isWide),
                  _sectionTitle('Browse the hive'),
                  _CategoryChips(
                    selected: selectedCategory,
                    onSelected: (category) => setState(() => selectedCategory = category),
                  ),
                  _sectionTitle('Popular picks'),
                  _ProductGrid(products: visibleProducts, width: width),
                  _PromoBanner(width: width),
                  const SizedBox(height: 28),
                ],
              ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
        child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF2B2B2B))),
      );
}

class _HeroSection extends StatelessWidget {
  final bool isWide;
  const _HeroSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7), decoration: BoxDecoration(color: const Color(0xFFF5A623), borderRadius: BorderRadius.circular(30)), child: const Text('New season drop', style: TextStyle(fontWeight: FontWeight.bold))),
        const SizedBox(height: 20),
        const Text('Shop the whole hive of deals', style: TextStyle(color: Color(0xFFFFF8E7), fontSize: 42, height: 1.05, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        const Text('Fresh finds, honest prices, and a little buzz in every box.', style: TextStyle(color: Color(0xFFC9BD9A), fontSize: 16)),
        const SizedBox(height: 26),
        Wrap(spacing: 12, runSpacing: 10, children: [
          AppButton(label: 'Start shopping', amber: true, onPressed: () => Navigator.pushNamed(context, '/productGrid')),
          OutlinedButton(onPressed: () => Navigator.pushNamed(context, '/productGrid'), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFFF8E7), side: const BorderSide(color: Color(0xFFFFF8E7))), child: const Text('Browse deals')),
        ]),
      ],
    );
    return Container(
      color: const Color(0xFF2B2B2B),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 42),
      child: isWide
          ? Row(children: [Expanded(child: copy), const SizedBox(width: 30), Expanded(child: Image.asset('assets/frenzybees_logo.png', height: 260))])
          : Column(children: [copy, const SizedBox(height: 24), Image.asset('assets/frenzybees_logo.png', height: 190)]),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  const _CategoryChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(children: _HomePageState.categories.map((category) {
          final active = category == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(label: Text(category), selected: active, onSelected: (_) => onSelected(category), selectedColor: const Color(0xFFF5A623), backgroundColor: Colors.white, side: const BorderSide(color: Color(0xFFEADFC0)), labelStyle: TextStyle(color: active ? const Color(0xFF2B2B2B) : Colors.black87, fontWeight: FontWeight.w600)),
          );
        }).toList()),
      );
}

class _ProductGrid extends StatelessWidget {
  final List<Product> products;
  final double width;
  const _ProductGrid({required this.products, required this.width});

  @override
  Widget build(BuildContext context) {
    final columns = width > 900 ? 4 : width >= 500 ? 2 : 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: .78),
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(product: product, index: index, onTap: () => Navigator.pushNamed(context, '/productDetail', arguments: product));
      },
    );
  }
}

class _PromoBanner extends StatelessWidget {
  final double width;
  const _PromoBanner({required this.width});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(24, 30, 24, 0),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(color: const Color(0xFFF5A623), borderRadius: BorderRadius.circular(16)),
        child: width > 500
            ? Row(children: [const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Limited time', style: TextStyle(fontWeight: FontWeight.bold)), SizedBox(height: 4), Text('Free delivery on orders over \$50', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))])), _shopButton(context)])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Limited time', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 4), const Text('Free delivery on orders over \$50', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)), const SizedBox(height: 14), _shopButton(context)]),
      );

  Widget _shopButton(BuildContext context) => AppButton(label: 'Shop now', onPressed: () => Navigator.pushNamed(context, '/productGrid'));
}
