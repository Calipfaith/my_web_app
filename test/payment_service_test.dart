import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frenzybees/services/payment_service.dart';

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

  test('parses payment intent verification response', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/payment-intents/verify');
      return http.Response(
        '{"orderId":"order_test","paymentIntentId":"pi_test","status":"succeeded","orderStatus":"paid"}',
        200,
      );
    });

    final result = await PaymentService(client: client).verifyPaymentIntent(
      orderId: 'order_test',
      paymentIntentId: 'pi_test',
    );

    expect(result['orderStatus'], 'paid');
  });

  test('parses a hosted checkout session response', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/checkout-sessions');
      return http.Response(
        '{"sessionId":"cs_test","url":"https://checkout.stripe.com/test"}',
        201,
      );
    });

    final result = await PaymentService(client: client).createCheckoutSession(
      orderId: 'order_test',
      cartItems: const [
        {'name': 'Sneakers', 'price': 120, 'quantity': 1},
      ],
    );

    expect(result.host, 'checkout.stripe.com');
  });

  test('parses hosted checkout verification response', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/checkout-sessions/verify');
      return http.Response(
        '{"orderId":"order_test","sessionId":"cs_test","status":"paid","orderStatus":"paid"}',
        200,
      );
    });

    final result = await PaymentService(client: client).verifyCheckoutSession(
      sessionId: 'cs_test',
    );

    expect(result['orderStatus'], 'paid');
  });
}
