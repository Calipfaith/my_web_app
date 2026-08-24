import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

class ProfileStore {
  static const _nameKey = 'profile_name';
  static const _phoneKey = 'profile_phone';
  static const _addressKey = 'profile_address';
  static const _paymentKey = 'profile_payment';
  static const _notificationsKey = 'profile_notifications';

  static Future<Map<String, String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_nameKey) ?? '',
      'phone': prefs.getString(_phoneKey) ?? '',
      'address': prefs.getString(_addressKey) ?? '',
      'payment': prefs.getString(_paymentKey) ?? '',
    };
  }

  static Future<void> save({
    required String name,
    required String phone,
    required String address,
    required String payment,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name.trim());
    await prefs.setString(_phoneKey, phone.trim());
    await prefs.setString(_addressKey, address.trim());
    await prefs.setString(_paymentKey, payment.trim());
  }

  static Future<bool> notificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsKey) ?? true;
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }

  final http.Client client;
  final String baseUrl;

  ProfileStore({http.Client? client, String? baseUrl})
    : client = client ?? http.Client(),
      baseUrl =
          baseUrl ??
          const String.fromEnvironment('CATALOG_API_URL', defaultValue: '');

  Future<Map<String, dynamic>> loadRemote() async {
    final endpoint = baseUrl.isEmpty ? '/api/profile' : '$baseUrl/api/profile';
    final response = await client.get(
      Uri.parse(endpoint),
      headers: AuthService.authHeaders(),
    );
    if (response.statusCode != 200)
      throw Exception('Profile request failed: ${response.statusCode}');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateRemote(Map<String, dynamic> values) async {
    final endpoint = baseUrl.isEmpty ? '/api/profile' : '$baseUrl/api/profile';
    final response = await client.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders(),
      },
      body: jsonEncode(values),
    );
    if (response.statusCode != 200)
      throw Exception('Profile update failed: ${response.statusCode}');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getRewards() async {
    final endpoint = baseUrl.isEmpty ? '/api/rewards' : '$baseUrl/api/rewards';
    final response = await client.get(
      Uri.parse(endpoint),
      headers: AuthService.authHeaders(),
    );
    if (response.statusCode != 200)
      throw Exception('Rewards request failed: ${response.statusCode}');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> redeemReward({
    int points = 100,
    String reward = 'discount',
  }) async {
    final endpoint = baseUrl.isEmpty
        ? '/api/rewards/redeem'
        : '$baseUrl/api/rewards/redeem';
    final response = await client.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders(),
      },
      body: jsonEncode({'points': points, 'reward': reward}),
    );
    if (response.statusCode != 200)
      throw Exception('Rewards redemption failed: ${response.statusCode}');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
