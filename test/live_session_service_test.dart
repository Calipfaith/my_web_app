import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frenzybees/services/live_session_service.dart';

void main() {
  test('loads an active live session', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/live-sessions/drop-1');
      return http.Response(
        jsonEncode({'dropId': 'drop-1', 'status': 'live', 'viewerCount': 12}),
        200,
      );
    });

    final session = await LiveSessionService(client: client).fetch('drop-1');

    expect(session['status'], 'live');
    expect(session['viewerCount'], 12);
  });

  test('updates a live session status', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/live-sessions/drop-1/status');
      expect(jsonDecode(request.body)['status'], 'completed');
      return http.Response(
        jsonEncode({'dropId': 'drop-1', 'status': 'completed'}),
        200,
      );
    });

    final session = await LiveSessionService(client: client)
        .update('drop-1', 'completed');

    expect(session['status'], 'completed');
  });

  test('updates viewer presence', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/live-sessions/drop-1/presence');
      expect(jsonDecode(request.body)['joining'], true);
      return http.Response(
        jsonEncode({'dropId': 'drop-1', 'viewerCount': 13}),
        200,
      );
    });

    final session = await LiveSessionService(client: client)
        .presence(sessionId: 'drop-1', joining: true);

    expect(session['viewerCount'], 13);
  });
}
