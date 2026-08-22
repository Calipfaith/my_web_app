import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:my_web_app/services/payment_service.dart';

void main() {
  test('parses a Stripe payment intent response', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/payment-intents');
      return http.Response(
        '{"paymentIntentId":"pi_test","clientSecret":"secret_test","status":"requires_payment_method"}',
        201,
      );
    });

    final result = await PaymentService(client: client).createPaymentIntent(
      orderId: 'order_test',
      amountInMinorUnits: 12000,
    );

    expect(result['paymentIntentId'], 'pi_test');
    expect(result['status'], 'requires_payment_method');
  });
}
