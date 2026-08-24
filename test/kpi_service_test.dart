import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frenzybees/services/kpi_service.dart';

void main() {
  test('loads partner KPI payload', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/kpis/partner');
      return http.Response(
        jsonEncode({
          'activeClients': 12,
          'fulfilledOrders': 34,
          'commissionPool': 1200.0,
        }),
        200,
      );
    });

    final result = await KpiService(client: client).fetchPartnerKpis();

    expect(result['activeClients'], 12);
    expect(result['fulfilledOrders'], 34);
  });

  test('loads admin KPI payload', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/kpis/admin');
      return http.Response(
        jsonEncode({'catalogProducts': 88, 'pendingOrders': 7, 'gmv': 9150.5}),
        200,
      );
    });

    final result = await KpiService(client: client).fetchAdminKpis();

    expect(result['catalogProducts'], 88);
    expect(result['pendingOrders'], 7);
  });

  test('loads investor KPI payload', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/kpis/investor');
      return http.Response(
        jsonEncode({
          'gmv': 10000,
          'activeCustomers': 55,
          'settlementRate': 98.5,
          'nectarIssued': 2500,
        }),
        200,
      );
    });

    final result = await KpiService(client: client).fetchInvestorKpis();

    expect(result['activeCustomers'], 55);
    expect(result['settlementRate'], 98.5);
  });

  test('builds seven-point trend series', () {
    final trend = KpiService().buildTrendSeries(100);
    expect(trend.length, 7);
    expect(trend.first, lessThan(trend.last));
  });

  test('flags partner thresholds when values are low', () {
    final alerts = KpiService().partnerAlerts({
      'activeClients': 2,
      'avgOrderValue': 50,
      'commissionPool': 100,
    });
    expect(alerts.length, 3);
  });

  test('flags investor settlement risk when below threshold', () {
    final alerts = KpiService().investorAlerts({
      'settlementRate': 90,
      'activeCustomers': 10,
      'gmv': 2000,
    });
    expect(alerts, isNotEmpty);
  });
}
