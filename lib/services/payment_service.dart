import 'dart:convert';

import 'package:http/http.dart' as http;
import 'auth_service.dart';

class PaymentService {
  final http.Client client;
  final String baseUrl;

  PaymentService({http.Client? client, String? baseUrl})
      : client = client ?? http.Client(),
        baseUrl = baseUrl ?? const String.fromEnvironment(
          'CATALOG_API_URL',
          defaultValue: '',
        );

  Future<Map<String, dynamic>> createPaymentIntent({
    required String orderId,
    required int amountInMinorUnits,
  }) async {
    final endpoint = baseUrl.isEmpty
        ? '/api/payment-intents'
        : '$baseUrl/api/payment-intents';
    final response = await client.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json', ...AuthService.authHeaders()},
      body: jsonEncode({
        'orderId': orderId,
        'amount': amountInMinorUnits,
        'currency': 'myr',
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Payment request failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyPaymentIntent({
    required String orderId,
    required String paymentIntentId,
  }) async {
    final endpoint = baseUrl.isEmpty
        ? '/api/payment-intents/verify'
        : '$baseUrl/api/payment-intents/verify';
    final response = await client.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json', ...AuthService.authHeaders()},
      body: jsonEncode({
        'orderId': orderId,
        'paymentIntentId': paymentIntentId,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Payment verification failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Uri> createCheckoutSession({
    required String orderId,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    final endpoint = baseUrl.isEmpty
        ? '/api/checkout-sessions'
        : '$baseUrl/api/checkout-sessions';
    final response = await client.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json', ...AuthService.authHeaders()},
      body: jsonEncode({'orderId': orderId, 'cartItems': cartItems}),
    );
    if (response.statusCode != 201) {
      throw Exception('Checkout session failed: ${response.statusCode}');
    }
    final url = (jsonDecode(response.body) as Map<String, dynamic>)['url'] as String;
    return Uri.parse(url);
  }

  Future<Map<String, dynamic>> verifyCheckoutSession({
    required String sessionId,
  }) async {
    final endpoint = baseUrl.isEmpty
        ? '/api/checkout-sessions/verify'
        : '$baseUrl/api/checkout-sessions/verify';
    final response = await client.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json', ...AuthService.authHeaders()},
      body: jsonEncode({'sessionId': sessionId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Checkout verification failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}