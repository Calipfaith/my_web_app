import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frenzybees/services/order_service.dart';

void main() {
  test('includes live attribution fields when creating an order', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/orders');
      final body = request.body;
      expect(body.contains('"sessionId":"drop_1"'), isTrue);
      expect(body.contains('"hostId":"queen_1"'), isTrue);
      return http.Response('{"orderId":"order_1"}', 201);
    });

    final orderId = await OrderService(client: client).createOrder(
      address: 'Hive Street',
      contact: '+6012345678',
      paymentMethod: 'Credit Card',
      cartItems: const [
        {'name': 'Sneakers', 'price': 120, 'quantity': 1},
      ],
      sessionId: 'drop_1',
      hostId: 'queen_1',
    );

    expect(orderId, 'order_1');
  });

  test('parses order settlement verification response', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/orders/order_2/settlement');
      return http.Response(
        '{"orderId":"order_2","hasLiveAttribution":true,"hasSettlement":true,"settlement":{"settlementId":"order_2"}}',
        200,
      );
    });

    final result = await OrderService(client: client)
        .getOrderSettlement('order_2');

    expect(result['hasLiveAttribution'], isTrue);
    expect(result['hasSettlement'], isTrue);
    expect(
      (result['settlement'] as Map<String, dynamic>)['settlementId'],
      'order_2',
    );
  });
}
