import 'package:flutter/material.dart';

import '../services/order_service.dart';
import '../widgets/app_scaffold.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: OrderService().getMyOrders(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return const Text('Unable to load your orders');
            final orders = snapshot.data ?? [];
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Your order history', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              if (orders.isEmpty) const Text('No orders in your hive yet.'),
              ...orders.map((order) => ListTile(title: Text('Order ${order['orderId']}'), trailing: Text('${order['status']}'))),
            ]);
          },
        ),
      ),
    );
  }
}