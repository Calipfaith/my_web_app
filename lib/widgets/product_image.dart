import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String name;
  final double? height;

  const ProductImage({super.key, required this.name, this.height});

  IconData get _icon {
    switch (name.toLowerCase()) {
      case 'sneakers':
        return Icons.directions_run;
      case 'handbag':
        return Icons.shopping_bag;
      case 'headphones':
        return Icons.headphones;
      case 'smartphone':
        return Icons.smartphone;
      case 'men':
      case 'women':
        return Icons.checkroom;
      case 'electronics':
        return Icons.devices;
      case 'accessories':
        return Icons.watch;
      default:
        return Icons.shopping_basket;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Icon(
          _icon,
          size: height == null ? 64 : height! * 0.55,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}