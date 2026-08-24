import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class OrderService {
  final http.Client client;
  final String baseUrl;

  OrderService({http.Client? client, String? baseUrl})
    : client = client ?? http.Client(),
      baseUrl =
          baseUrl ??
          const String.fromEnvironment('CATALOG_API_URL', defaultValue: '');

  Future<String> createOrder({
    required String address,
    required String contact,
    required String paymentMethod,
    required List<Map<String, dynamic>> cartItems,
    String? sessionId,
    String? hostId,
  }) async {
    final endpoint = baseUrl.isEmpty ? '/api/orders' : '$baseUrl/api/orders';
    final response = await client.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders(),
      },
      body: jsonEncode({
        'address': address,
        'contact': contact,
        'paymentMethod': paymentMethod,
        'cartItems': cartItems,
        if (sessionId != null) 'sessionId': sessionId,
        if (hostId != null) 'hostId': hostId,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Order request failed: ${response.statusCode}');
    }
    return (jsonDecode(response.body) as Map<String, dynamic>)['orderId']
        as String;
  }

  Future<List<Map<String, dynamic>>> getMyOrders() async {
    final endpoint = baseUrl.isEmpty ? '/api/orders' : '$baseUrl/api/orders';
    final response = await client.get(
      Uri.parse(endpoint),
      headers: AuthService.authHeaders(),
    );
    if (response.statusCode != 200)
      throw Exception('Order history failed: ${response.statusCode}');
    return (jsonDecode(response.body) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getOrderSettlement(String orderId) async {
    final endpoint = baseUrl.isEmpty
        ? '/api/orders/$orderId/settlement'
        : '$baseUrl/api/orders/$orderId/settlement';
    final response = await client.get(
      Uri.parse(endpoint),
      headers: AuthService.authHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Order settlement lookup failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
