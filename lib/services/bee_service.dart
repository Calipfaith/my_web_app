import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class BeeService {
  final http.Client client;
  final String baseUrl;

  BeeService({http.Client? client, String? baseUrl})
    : client = client ?? http.Client(),
      baseUrl =
          baseUrl ??
          const String.fromEnvironment('CATALOG_API_URL', defaultValue: '');

  Future<Map<String, dynamic>> fetchDashboard() async {
    final endpoint = baseUrl.isEmpty
        ? '/api/bee/dashboard'
        : '$baseUrl/api/bee/dashboard';
    final response = await client.get(
      Uri.parse(endpoint),
      headers: AuthService.authHeaders(),
    );
    if (response.statusCode != 200)
      throw Exception('Bee dashboard failed: ${response.statusCode}');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createDrop({
    required String title,
    required String date,
    required String product,
  }) async {
    final endpoint = baseUrl.isEmpty
        ? '/api/bee/drops'
        : '$baseUrl/api/bee/drops';
    final response = await client.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders(),
      },
      body: jsonEncode({'title': title, 'date': date, 'product': product}),
    );
    if (response.statusCode != 201)
      throw Exception('Bee drop creation failed: ${response.statusCode}');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> inviteCoHost(String username) async {
    final endpoint = baseUrl.isEmpty
        ? '/api/bee/collaborations'
        : '$baseUrl/api/bee/collaborations';
    final response = await client.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders(),
      },
      body: jsonEncode({'username': username}),
    );
    if (response.statusCode != 201)
      throw Exception('Co-host invitation failed: ${response.statusCode}');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateDropStatus({
    required String dropId,
    required String status,
  }) async {
    final endpoint = baseUrl.isEmpty
        ? '/api/bee/drops/$dropId/status'
        : '$baseUrl/api/bee/drops/$dropId/status';
    final response = await client.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders(),
      },
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode != 200)
      throw Exception('Drop status update failed: ${response.statusCode}');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchCollaborations() async {
    final endpoint = baseUrl.isEmpty
        ? '/api/bee/collaborations'
        : '$baseUrl/api/bee/collaborations';
    final response = await client.get(
      Uri.parse(endpoint),
      headers: AuthService.authHeaders(),
    );
    if (response.statusCode != 200)
      throw Exception('Collaboration lookup failed: ${response.statusCode}');
    return (jsonDecode(response.body) as Map<String, dynamic>)['collaborations']
        as List<dynamic>;
  }

  Future<void> decideCollaboration({
    required String collaborationId,
    required String decision,
  }) async {
    final endpoint = baseUrl.isEmpty
        ? '/api/bee/collaborations/$collaborationId/decision'
        : '$baseUrl/api/bee/collaborations/$collaborationId/decision';
    final response = await client.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders(),
      },
      body: jsonEncode({'decision': decision}),
    );
    if (response.statusCode != 200)
      throw Exception('Collaboration decision failed: ${response.statusCode}');
  }
}
