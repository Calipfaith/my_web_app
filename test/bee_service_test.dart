import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frenzybees/services/bee_service.dart';

void main() {
  test('loads Bee dashboard metrics', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/bee/dashboard');
      return http.Response(
        jsonEncode({
          'nextDrop': 'Fashion Haul',
          'honeycombs': 3,
          'views': 1200,
          'sales': 350,
          'nectar': 300,
        }),
        200,
      );
    });

    final dashboard = await BeeService(client: client).fetchDashboard();

    expect(dashboard['nextDrop'], 'Fashion Haul');
    expect(dashboard['honeycombs'], 3);
    expect(dashboard['sales'], 350);
  });

  test('rejects failed Bee dashboard requests', () async {
    final client = MockClient(
      (request) async => http.Response('Forbidden', 403),
    );

    expect(
      () => BeeService(client: client).fetchDashboard(),
      throwsA(isA<Exception>()),
    );
  });
}
