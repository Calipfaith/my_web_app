import 'package:flutter/material.dart';

import '../services/kpi_service.dart';
import '../widgets/app_scaffold.dart';

class PartnerDashboardPage extends StatelessWidget {
  const PartnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = KpiService();
    return AppScaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<Map<String, dynamic>>(
          future: service.fetchPartnerKpis(),
          builder: (context, snapshot) {
            final data = snapshot.data ?? const <String, dynamic>{};
            final alerts = service.partnerAlerts(data);
            final trend =
                _trendValues(data['fulfilledOrdersTrend']) ??
                service.buildTrendSeries(
                  (data['fulfilledOrders'] as num?)?.toDouble() ?? 0,
                );
            return ListView(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Partner Operations',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Client servicing, fulfillment, and commission pulse',
                    ),
                    const SizedBox(height: 20),
                    _metric('Active clients', '${data['activeClients'] ?? 0}'),
                    _metric(
                      'Fulfilled orders',
                      '${data['fulfilledOrders'] ?? 0}',
                    ),
                    _metric(
                      'Commission pool',
                      'RM${(data['commissionPool'] ?? 0).toString()}',
                    ),
                    _metric(
                      'Average order value',
                      'RM${(data['avgOrderValue'] ?? 0).toString()}',
                    ),
                    _metric('Live sessions', '${data['liveSessions'] ?? 0}'),
                    _alerts('Threshold alerts', alerts),
                    _trend('7-day fulfilled order trend', trend),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<double>? _trendValues(dynamic raw) {
    if (raw is! List) {
      return null;
    }
    return raw.map((value) => (value as num).toDouble()).toList();
  }

  Widget _metric(String label, String value) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
  );

  Widget _alerts(String title, List<String> alerts) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (alerts.isEmpty)
            const Text('All partner KPI thresholds are healthy.')
          else
            for (final alert in alerts)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $alert'),
              ),
        ],
      ),
    ),
  );

  Widget _trend(String title, List<double> values) {
    final maxValue = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            SizedBox(
              height: 88,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final value in values)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Container(
                          height: maxValue == 0 ? 0 : (value / maxValue) * 88,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5A623),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
