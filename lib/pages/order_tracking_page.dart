import 'package:flutter/material.dart';
import '../services/tracking_service.dart';
import '../widgets/app_scaffold.dart';

class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({super.key});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  Future<Map<String, dynamic>>? orderFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orderId = ModalRoute.of(context)?.settings.arguments as String?;
    orderFuture ??= TrackingService().getOrder(orderId ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final orderId = ModalRoute.of(context)!.settings.arguments as String?;

    return AppScaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Bee on the way!\nOrder ID: ${orderId ?? "N/A"}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            FutureBuilder<Map<String, dynamic>>(
              future: orderFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return const Text('Unable to load order status');
                }
                return Text('Status: ${snapshot.data?['status'] ?? 'unknown'}');
              },
            ),
          ],
        ),
      ),
    );
  }
}
