import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class KpiService {
  final http.Client client;
  final String baseUrl;

  static final partnerMinActiveClients =
      double.tryParse(
        const String.fromEnvironment(
          'PARTNER_MIN_ACTIVE_CLIENTS',
          defaultValue: '5',
        ),
      ) ??
      5;
  static final partnerMinAvgOrderValue =
      double.tryParse(
        const String.fromEnvironment(
          'PARTNER_MIN_AVG_ORDER_VALUE',
          defaultValue: '80',
        ),
      ) ??
      80;
  static final partnerMinCommissionPool =
      double.tryParse(
        const String.fromEnvironment(
          'PARTNER_MIN_COMMISSION_POOL',
          defaultValue: '300',
        ),
      ) ??
      300;
  static final adminMinGmv =
      double.tryParse(
        const String.fromEnvironment('ADMIN_MIN_GMV', defaultValue: '1000'),
      ) ??
      1000;
  static final investorMinSettlementRate =
      double.tryParse(
        const String.fromEnvironment(
          'INVESTOR_MIN_SETTLEMENT_RATE',
          defaultValue: '95',
        ),
      ) ??
      95;
  static final investorMinActiveCustomers =
      double.tryParse(
        const String.fromEnvironment(
          'INVESTOR_MIN_ACTIVE_CUSTOMERS',
          defaultValue: '20',
        ),
      ) ??
      20;
  static final investorMinGmv =
      double.tryParse(
        const String.fromEnvironment('INVESTOR_MIN_GMV', defaultValue: '5000'),
      ) ??
      5000;

  KpiService({http.Client? client, String? baseUrl})
    : client = client ?? http.Client(),
      baseUrl =
          baseUrl ??
          const String.fromEnvironment('CATALOG_API_URL', defaultValue: '');

  Future<Map<String, dynamic>> _get(String path) async {
    final endpoint = baseUrl.isEmpty ? path : '$baseUrl$path';
    final response = await client.get(
      Uri.parse(endpoint),
      headers: AuthService.authHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('KPI request failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchPartnerKpis() => _get('/api/kpis/partner');
  Future<Map<String, dynamic>> fetchAdminKpis() => _get('/api/kpis/admin');
  Future<Map<String, dynamic>> fetchInvestorKpis() =>
      _get('/api/kpis/investor');

  List<double> buildTrendSeries(num currentValue) {
    final current = currentValue.toDouble();
    if (current <= 0) {
      return const [0, 0, 0, 0, 0, 0, 0];
    }
    const multipliers = [0.72, 0.8, 0.89, 0.94, 0.97, 1.0, 1.06];
    return multipliers
        .map((m) => double.parse((current * m).toStringAsFixed(2)))
        .toList();
  }

  List<String> partnerAlerts(Map<String, dynamic> data) {
    final alerts = <String>[];
    final activeClients = (data['activeClients'] as num?)?.toDouble() ?? 0;
    final avgOrderValue = (data['avgOrderValue'] as num?)?.toDouble() ?? 0;
    final commissionPool = (data['commissionPool'] as num?)?.toDouble() ?? 0;
    if (activeClients < partnerMinActiveClients) {
      alerts.add(
        'Low active clients: below threshold ${partnerMinActiveClients.toStringAsFixed(0)}.',
      );
    }
    if (avgOrderValue < partnerMinAvgOrderValue) {
      alerts.add(
        'Average order value below RM${partnerMinAvgOrderValue.toStringAsFixed(0)} target.',
      );
    }
    if (commissionPool < partnerMinCommissionPool) {
      alerts.add(
        'Commission pool below RM${partnerMinCommissionPool.toStringAsFixed(0)} target.',
      );
    }
    return alerts;
  }

  List<String> adminAlerts(Map<String, dynamic> data) {
    final alerts = <String>[];
    final pendingOrders = (data['pendingOrders'] as num?)?.toDouble() ?? 0;
    final paidOrders = (data['paidOrders'] as num?)?.toDouble() ?? 0;
    final gmv = (data['gmv'] as num?)?.toDouble() ?? 0;
    if (pendingOrders > paidOrders) {
      alerts.add(
        'Fulfillment backlog risk: pending orders exceed paid orders.',
      );
    }
    if (gmv < adminMinGmv) {
      alerts.add('GMV is below RM${adminMinGmv.toStringAsFixed(0)} baseline.');
    }
    return alerts;
  }

  List<String> investorAlerts(Map<String, dynamic> data) {
    final alerts = <String>[];
    final settlementRate = (data['settlementRate'] as num?)?.toDouble() ?? 0;
    final activeCustomers = (data['activeCustomers'] as num?)?.toDouble() ?? 0;
    final gmv = (data['gmv'] as num?)?.toDouble() ?? 0;
    if (settlementRate < investorMinSettlementRate) {
      alerts.add(
        'Settlement confidence risk: below ${investorMinSettlementRate.toStringAsFixed(0)}% threshold.',
      );
    }
    if (activeCustomers < investorMinActiveCustomers) {
      alerts.add(
        'Customer growth risk: below ${investorMinActiveCustomers.toStringAsFixed(0)} active customers.',
      );
    }
    if (gmv < investorMinGmv) {
      alerts.add(
        'Revenue momentum risk: GMV below RM${investorMinGmv.toStringAsFixed(0)} baseline.',
      );
    }
    return alerts;
  }
}
