import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class QueenService {
  final http.Client client;
  final String baseUrl;

  QueenService({http.Client? client, String? baseUrl})
    : client = client ?? http.Client(),
      baseUrl =
          baseUrl ??
          const String.fromEnvironment('CATALOG_API_URL', defaultValue: '');

  Future<Map<String, dynamic>> _get(String path) async {
    final endpoint = baseUrl.isEmpty ? path : '$baseUrl$path';
    final response = await client.get(
      Uri.parse(endpoint),
      headers: AuthService.authHeaders(),
    );
    if (response.statusCode != 200)
      throw Exception('Queen request failed: ${response.statusCode}');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchDrops() async =>
      (await _get('/api/queen/drops'))['drops'] as List<dynamic>;
  Future<List<dynamic>> fetchEvents() async =>
      (await _get('/api/queen/events'))['events'] as List<dynamic>;
  Future<Map<String, dynamic>> fetchRewards() async =>
      _get('/api/queen/rewards');
  Future<Map<String, dynamic>> fetchAnalytics() async =>
      _get('/api/queen/analytics');

  Future<List<dynamic>> fetchChat(String dropId) async =>
      (await _get('/api/chat/$dropId'))['comments'] as List<dynamic>;

  Future<void> postChat(String dropId, String message) async {
    final endpoint = baseUrl.isEmpty
        ? '/api/chat/$dropId'
        : '$baseUrl/api/chat/$dropId';
    final response = await client.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders(),
      },
      body: jsonEncode({'message': message}),
    );
    if (response.statusCode != 201)
      throw Exception('Chat message failed: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> createEvent({
    required String title,
    required String date,
    String reward = '0 Nectar',
  }) async {
    final endpoint = baseUrl.isEmpty
        ? '/api/queen/events'
        : '$baseUrl/api/queen/events';
    final response = await client.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders(),
      },
      body: jsonEncode({'title': title, 'date': date, 'reward': reward}),
    );
    if (response.statusCode != 201) {
      throw Exception('Event creation failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
