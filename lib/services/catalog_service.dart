import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

class CatalogService {
  final http.Client client;
  final String baseUrl;

  CatalogService({http.Client? client, String? baseUrl})
      : client = client ?? http.Client(),
        baseUrl = baseUrl ?? const String.fromEnvironment(
          'CATALOG_API_URL',
          defaultValue: '',
        );

  Future<List<Product>> getProducts() async {
    final endpoint = baseUrl.isEmpty ? '/api/products' : '$baseUrl/api/products';
    final response = await client.get(Uri.parse(endpoint));
    if (response.statusCode != 200) {
      throw Exception('Catalog request failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}