import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/product_image.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return AppScaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: cart.items.isEmpty
            ? const SizedBox(
                height: 360,
                child: Center(child: Text('Your hive is empty')),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your hive',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 16),
                  ...cart.items.map(
                    (item) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: SizedBox(
                          width: 56,
                          child: ProductImage(name: item.name, height: 50),
                        ),
                        title: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('RM${item.price.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Decrease quantity',
                              icon: const Icon(Icons.remove),
                              onPressed: () => item.quantity > 1
                                  ? cart.updateQuantity(item, item.quantity - 1)
                                  : cart.removeItem(item),
                            ),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Increase quantity',
                              icon: const Icon(Icons.add),
                              onPressed: () =>
                                  cart.updateQuantity(item, item.quantity + 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Total: RM${cart.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Fly to checkout',
                    onPressed: () => Navigator.pushNamed(context, '/checkout'),
                  ),
                ],
              ),
      ),
    );
  }
}
