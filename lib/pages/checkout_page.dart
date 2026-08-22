import 'package:flutter/material.dart';

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
                value: paymentMethod,
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
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    Navigator.pushNamed(
                      context,
                      '/confirmation',
                      arguments: {
                        "address": address,
                        "contact": contact,
                        "paymentMethod": paymentMethod,
                        "cartItems": widget.cartItems,
                      },
                    );
                  }
                },
                child: Text("Place Order"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
