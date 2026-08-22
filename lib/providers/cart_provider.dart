// lib/providers/cart_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart.dart'; // <- correct relative path

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  CartProvider() {
    _loadCart();
  }

  void addItem(CartItem item) {
    final index = _items.indexWhere((i) => i.name == item.name);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(item);
    }
    _saveCart();
    notifyListeners();
  }

  void removeItem(CartItem item) {
    _items.removeWhere((i) => i.name == item.name);
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(CartItem item, int quantity) {
    final index = _items.indexWhere((i) => i.name == item.name);
    if (index >= 0) {
      _items[index].quantity = quantity;
      _saveCart();
      notifyListeners();
    }
  }

  double get totalPrice =>
      _items.fold(0.0, (sum, item) => sum + item.price * item.quantity);

  void clearCart() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }

  // Persistence
  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = jsonEncode(_items.map((i) => i.toMap()).toList());
    await prefs.setString('cart', cartJson);
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString('cart');
    if (cartJson != null && cartJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(cartJson) as List<dynamic>;
        _items.clear();
        _items.addAll(decoded.map((e) => CartItem.fromMap(Map<String, dynamic>.from(e))));
        notifyListeners();
      } catch (e) {
        // If parsing fails, clear stored value to avoid repeated errors
        await prefs.remove('cart');
      }
    }
  }
}
