import 'package:flutter/material.dart';

import '../services/kpi_service.dart';
import '../widgets/app_scaffold.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = KpiService();
    return AppScaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<Map<String, dynamic>>(
          future: service.fetchAdminKpis(),
          builder: (context, snapshot) {
            final data = snapshot.data ?? const <String, dynamic>{};
            final alerts = service.adminAlerts(data);
            final trend =
                _trendValues(data['gmvTrend']) ??
                service.buildTrendSeries(
                  (data['gmv'] as num?)?.toDouble() ?? 0,
                );
            return ListView(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Control Center',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Catalog, order risk, and operational health'),
                    const SizedBox(height: 20),
                    _metric(
                      'Catalog products',
                      '${data['catalogProducts'] ?? 0}',
                    ),
                    _metric('Pending orders', '${data['pendingOrders'] ?? 0}'),
                    _metric('Paid orders', '${data['paidOrders'] ?? 0}'),
                    _metric('Gross merchandise value', 'RM${data['gmv'] ?? 0}'),
                    _metric('Live sessions', '${data['liveSessions'] ?? 0}'),
                    _alerts('Threshold alerts', alerts),
                    _trend('7-day GMV trend', trend),
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
            const Text('All admin KPI thresholds are healthy.')
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
                            color: const Color(0xFF2B2B2B),
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
