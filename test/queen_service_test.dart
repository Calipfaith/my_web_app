import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frenzybees/services/queen_service.dart';

void main() {
  test('loads featured drops', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/queen/drops');
      return http.Response(
        jsonEncode({
          'drops': [
            {'name': 'Sneakers', 'nectar': 10},
          ],
        }),
        200,
      );
    });

    final drops = await QueenService(client: client).fetchDrops();

    expect(drops.single['name'], 'Sneakers');
  });

  test('loads Queen analytics', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/queen/analytics');
      return http.Response(jsonEncode({'gmv': 1200, 'repeatBuyers': 25}), 200);
    });

    final analytics = await QueenService(client: client).fetchAnalytics();

    expect(analytics['gmv'], 1200);
    expect(analytics['repeatBuyers'], 25);
  });

  test('posts a Hive Chat message', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/chat/drop-1');
      expect(jsonDecode(request.body)['message'], 'Is this available?');
      return http.Response('{}', 201);
    });

    await QueenService(client: client).postChat('drop-1', 'Is this available?');
  });

  test('creates a Queen event', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/queen/events');
      final body = jsonDecode(request.body);
      expect(body['title'], 'Fashion drop');
      expect(body['date'], '2026-09-01');
      return http.Response(
        jsonEncode({'eventId': 'event-1', 'title': body['title']}),
        201,
      );
    });

    final event = await QueenService(client: client)
        .createEvent(title: 'Fashion drop', date: '2026-09-01');

    expect(event['eventId'], 'event-1');
  });
}
