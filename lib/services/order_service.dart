import 'dart:convert';

import 'package:http/http.dart' as http;

class OrderService {
  final http.Client client;
  final String baseUrl;

  OrderService({http.Client? client, String? baseUrl})
      : client = client ?? http.Client(),
        baseUrl = baseUrl ?? const String.fromEnvironment(
          'CATALOG_API_URL',
          defaultValue: '',
        );

  Future<String> createOrder({
    required String address,
    required String contact,
    required String paymentMethod,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    final endpoint = baseUrl.isEmpty ? '/api/orders' : '$baseUrl/api/orders';
    final response = await client.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'address': address,
        'contact': contact,
        'paymentMethod': paymentMethod,
        'cartItems': cartItems,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Order request failed: ${response.statusCode}');
    }
    return (jsonDecode(response.body) as Map<String, dynamic>)['orderId']
        as String;
  }
}