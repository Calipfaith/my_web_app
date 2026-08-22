import 'dart:convert';

import 'package:http/http.dart' as http;

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
      headers: {'Content-Type': 'application/json'},
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
}