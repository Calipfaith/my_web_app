import 'package:flutter/material.dart';

import '../services/order_service.dart';
import '../services/payment_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_scaffold.dart';

class PaymentConfirmationPage extends StatefulWidget {
  const PaymentConfirmationPage({super.key});

  @override
  State<PaymentConfirmationPage> createState() =>
      _PaymentConfirmationPageState();
}

class _PaymentConfirmationPageState extends State<PaymentConfirmationPage> {
  Future<Map<String, dynamic>>? verification;
  Future<Map<String, dynamic>>? settlement;
  String? orderId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final argument = ModalRoute.of(context)?.settings.arguments;
    orderId = argument is String ? argument : null;
    final fragment = Uri.base.fragment;
    final query = fragment.contains('?') ? fragment.split('?').last : '';
    final sessionId =
        Uri.base.queryParameters['session_id'] ??
        (query.isEmpty ? null : Uri.splitQueryString(query)['session_id']);
    if (sessionId != null && verification == null) {
      verification = PaymentService().verifyCheckoutSession(
        sessionId: sessionId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = verification;
    return AppScaffold(
      body: SizedBox(
        height: 420,
        child: Center(
          child: result == null
              ? _confirmation(context, orderId, 'Payment is pending')
              : FutureBuilder<Map<String, dynamic>>(
                  future: result,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const CircularProgressIndicator();
                    }
                    final data = snapshot.data;
                    final paid = data?['orderStatus'] == 'paid';
                    final resolvedOrderId =
                        data?['orderId'] as String? ?? orderId;
                    if (paid && resolvedOrderId != null && settlement == null) {
                      settlement = OrderService().getOrderSettlement(
                        resolvedOrderId,
                      );
                    }
                    return _confirmation(
                      context,
                      resolvedOrderId,
                      paid ? 'Payment successful!' : 'Payment is pending',
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _confirmation(BuildContext context, String? id, String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle,
          color: Theme.of(context).colorScheme.primary,
          size: 80,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('Order ID: ${id ?? 'pending'}'),
        if (id != null && settlement != null) ...[
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>>(
            future: settlement,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              if (snapshot.hasError) {
                return const Text(
                  'Settlement verification unavailable',
                  style: TextStyle(color: Colors.black54),
                );
              }
              final details = snapshot.data ?? const <String, dynamic>{};
              final hasLiveAttribution = details['hasLiveAttribution'] == true;
              final hasSettlement = details['hasSettlement'] == true;
              return Column(
                children: [
                  Text(
                    hasLiveAttribution
                        ? 'Live attribution: verified'
                        : 'Live attribution: not detected',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasSettlement
                        ? 'Settlement: created'
                        : 'Settlement: pending',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              );
            },
          ),
        ],
        const SizedBox(height: 24),
        if (id != null)
          AppButton(
            label: 'Track order',
            onPressed: () =>
                Navigator.pushNamed(context, '/tracking', arguments: id),
          ),
      ],
    );
  }
}
