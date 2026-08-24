import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frenzybees/services/tracking_service.dart';

void main() {
  test('loads a persisted order status', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/orders/order_test');
      return http.Response('{"orderId":"order_test","status":"pending"}', 200);
    });

    final result = await TrackingService(client: client).getOrder('order_test');

    expect(result['orderId'], 'order_test');
    expect(result['status'], 'pending');
  });
}