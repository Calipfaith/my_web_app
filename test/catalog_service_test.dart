import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:my_web_app/services/catalog_service.dart';

void main() {
  test('parses products returned by the catalog API', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/products');
      return http.Response(
        '[{"name":"Demo Item","price":42,"category":"Men","image":"demo"}]',
        200,
      );
    });

    final result = await CatalogService(client: client).getProducts();

    expect(result.single.name, 'Demo Item');
    expect(result.single.price, 42);
    expect(result.single.category, 'Men');
  });
}