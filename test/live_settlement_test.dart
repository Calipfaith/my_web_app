import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frenzybees/services/live_session_service.dart';

void main() {
  test('calculates and returns commission settlement', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/live-sessions/drop-1/settle');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['amount'], 350);
      expect(body['queenRate'], .1);
      expect(body['beeRate'], .1);
      return http.Response(
        jsonEncode({
          'sessionId': 'drop-1',
          'amount': 350,
          'queenCommission': 35,
          'beeCommission': 35,
          'platformAmount': 280,
        }),
        201,
      );
    });

    final settlement = await LiveSessionService(client: client)
        .settle(sessionId: 'drop-1', amount: 350);

    expect(settlement['queenCommission'], 35);
    expect(settlement['beeCommission'], 35);
    expect(settlement['platformAmount'], 280);
  });
}
