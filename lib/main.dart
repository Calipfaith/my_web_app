import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import your provider + pages
import 'providers/cart_provider.dart';
import 'pages/persona_page.dart';
import 'pages/home_page.dart';
import 'pages/product_grid_page.dart';
import 'pages/product_detail_page.dart';
import 'pages/cart_page.dart';
import 'pages/checkout_page.dart';
import 'pages/payment_confirmation_page.dart';
import 'pages/order_tracking_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Shopper Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/home', // ← start on Home page for testing
      routes: {
        '/': (context) => PersonaPage(),
        '/home': (context) => HomePage(),
        '/productGrid': (context) => ProductGridPage(), // consistent name
        '/productDetail': (context) => ProductDetailPage(),
        '/cart': (context) => CartPage(),
        '/checkout': (context) => CheckoutPage(),
        '/confirmation': (context) => PaymentConfirmationPage(),
        '/tracking': (context) => OrderTrackingPage(),
      },
    );
  }
}
