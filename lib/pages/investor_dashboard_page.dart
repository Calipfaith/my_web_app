import 'package:flutter/material.dart';

import '../services/kpi_service.dart';
import '../widgets/app_scaffold.dart';

class InvestorDashboardPage extends StatelessWidget {
  const InvestorDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = KpiService();
    return AppScaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<Map<String, dynamic>>(
          future: service.fetchInvestorKpis(),
          builder: (context, snapshot) {
            final data = snapshot.data ?? const <String, dynamic>{};
            final alerts = service.investorAlerts(data);
            final trend =
                _trendValues(data['settlementRateTrend']) ??
                service.buildTrendSeries(
                  (data['settlementRate'] as num?)?.toDouble() ?? 0,
                );
            return ListView(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Investor Snapshot',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Revenue momentum, customer activity, and settlement confidence',
                    ),
                    const SizedBox(height: 20),
                    _metric('Gross merchandise value', 'RM${data['gmv'] ?? 0}'),
                    _metric(
                      'Active customers',
                      '${data['activeCustomers'] ?? 0}',
                    ),
                    _metric('Paid orders', '${data['paidOrders'] ?? 0}'),
                    _metric(
                      'Commission pool',
                      'RM${data['commissionPool'] ?? 0}',
                    ),
                    _metric(
                      'Settlement rate',
                      '${data['settlementRate'] ?? 0}%',
                    ),
                    _metric('Nectar issued', '${data['nectarIssued'] ?? 0}'),
                    _alerts('Threshold alerts', alerts),
                    _trend('7-day settlement rate trend', trend),
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
            const Text('All investor KPI thresholds are healthy.')
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
                            color: const Color(0xFF3A7D44),
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
