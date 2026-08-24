import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class LiveSessionService {
  final http.Client client;
  final String baseUrl;

  LiveSessionService({http.Client? client, String? baseUrl})
    : client = client ?? http.Client(),
      baseUrl =
          baseUrl ??
          const String.fromEnvironment('CATALOG_API_URL', defaultValue: '');

  Future<Map<String, dynamic>> get(String path) async {
    final endpoint = baseUrl.isEmpty ? path : '$baseUrl$path';
    final response = await client.get(
      Uri.parse(endpoint),
      headers: AuthService.authHeaders(),
    );
    if (response.statusCode != 200)
      throw Exception('Live session request failed: ${response.statusCode}');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(String sessionId, String status) async {
    final endpoint = baseUrl.isEmpty
        ? '/api/live-sessions/$sessionId/status'
        : '$baseUrl/api/live-sessions/$sessionId/status';
    final response = await client.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders(),
      },
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode != 200)
      throw Exception('Live session status failed: ${response.statusCode}');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetch(String sessionId) =>
      get('/api/live-sessions/$sessionId');

  Future<Map<String, dynamic>> create({
    required String title,
    required String product,
  }) async {
    final endpoint = baseUrl.isEmpty
        ? '/api/live-sessions'
        : '$baseUrl/api/live-sessions';
    final response = await client.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders(),
      },
      body: jsonEncode({'title': title, 'product': product}),
    );
    if (response.statusCode != 201)
      throw Exception('Live session creation failed: ${response.statusCode}');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> presence({
    required String sessionId,
    required bool joining,
  }) async {
    final endpoint = baseUrl.isEmpty
        ? '/api/live-sessions/$sessionId/presence'
        : '$baseUrl/api/live-sessions/$sessionId/presence';
    final response = await client.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders(),
      },
      body: jsonEncode({'joining': joining}),
    );
    if (response.statusCode != 200)
      throw Exception('Live presence update failed: ${response.statusCode}');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> settle({
    required String sessionId,
    required double amount,
    double queenRate = .10,
    double beeRate = .10,
  }) async {
    final endpoint = baseUrl.isEmpty
        ? '/api/live-sessions/$sessionId/settle'
        : '$baseUrl/api/live-sessions/$sessionId/settle';
    final response = await client.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders(),
      },
      body: jsonEncode({
        'amount': amount,
        'queenRate': queenRate,
        'beeRate': beeRate,
      }),
    );
    if (response.statusCode != 201)
      throw Exception('Settlement failed: ${response.statusCode}');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
