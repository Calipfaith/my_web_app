import 'dart:convert';

import 'package:http/http.dart' as http;

class TrackingService {
  final http.Client client;
  final String baseUrl;

  TrackingService({http.Client? client, String? baseUrl})
      : client = client ?? http.Client(),
        baseUrl = baseUrl ?? const String.fromEnvironment(
          'CATALOG_API_URL',
          defaultValue: '',
        );

  Future<Map<String, dynamic>> getOrder(String orderId) async {
    final encodedId = Uri.encodeComponent(orderId);
    final endpoint = baseUrl.isEmpty
        ? '/api/orders/$encodedId'
        : '$baseUrl/api/orders/$encodedId';
    final response = await client.get(Uri.parse(endpoint));
    if (response.statusCode != 200) {
      throw Exception('Order lookup failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}