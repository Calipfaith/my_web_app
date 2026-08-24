import 'package:flutter/material.dart';

import '../models/product.dart';
import 'product_image.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final int index;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.index = 0, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final discounted = index.isEven;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox.expand(child: ProductImage(name: product.image)),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(8)),
                  child: Text(discounted ? '-20%' : 'New', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: scheme.onPrimary)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(product.category, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 5),
          Row(children: [
            Text('RM${product.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            if (discounted) ...[
              const SizedBox(width: 8),
              Text('RM${(product.price * 1.25).toStringAsFixed(0)}', style: TextStyle(color: scheme.onSurfaceVariant, decoration: TextDecoration.lineThrough, fontSize: 12)),
            ],
          ]),
        ]),
      ),
    );
  }
}
