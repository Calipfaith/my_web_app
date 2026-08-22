import 'package:flutter/material.dart';

class OrderTrackingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final orderId = ModalRoute.of(context)!.settings.arguments as String?;

    final steps = [
      {"title": "Order Placed", "status": true},
      {"title": "Processing", "status": true},
      {"title": "Shipped", "status": false},
      {"title": "Delivered", "status": false},
    ];

    return Scaffold(
      appBar: AppBar(title: Text("Track Order")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Order ID: ${orderId ?? "N/A"}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  final step = steps[index];
                  final status = step["status"] as bool;   // ✅ cast to bool
                  final title = step["title"] as String;   // ✅ cast to String

                  return ListTile(
                    leading: Icon(
                      status ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: status ? Colors.green : Colors.grey,
                    ),
                    title: Text(title),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
