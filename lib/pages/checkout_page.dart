import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../services/order_service.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>>? cartItems;
  CheckoutPage({this.cartItems});

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  String address = "";
  String contact = "";
  String paymentMethod = "Credit Card";
  bool submitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Checkout")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: "Shipping Address"),
                validator: (value) =>
                    value!.isEmpty ? "Please enter your address" : null,
                onSaved: (value) => address = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Contact Number"),
                validator: (value) =>
                    value!.isEmpty ? "Please enter your contact number" : null,
                onSaved: (value) => contact = value!,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: paymentMethod,
                items: ["Credit Card", "PayPal", "Bank Transfer"]
                    .map((method) => DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => paymentMethod = value!),
                decoration: InputDecoration(labelText: "Payment Method"),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: submitting ? null : () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    setState(() => submitting = true);
                    try {
                      final cart = context.read<CartProvider>();
                      final orderId = await OrderService().createOrder(
                        address: address,
                        contact: contact,
                        paymentMethod: paymentMethod,
                        cartItems: cart.items.map((item) => item.toMap()).toList(),
                      );
                      if (!mounted) return;
                      Navigator.pushNamed(context, '/confirmation', arguments: orderId);
                    } catch (_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Unable to place order')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => submitting = false);
                    }
                  }
                },
                child: Text(submitting ? "Placing Order..." : "Place Order"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
