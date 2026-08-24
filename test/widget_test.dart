// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frenzybees/main.dart';
import 'package:frenzybees/models/product.dart';
import 'package:frenzybees/services/catalog_service.dart';

class _FakeCatalogService extends CatalogService {
  @override
  Future<List<Product>> getProducts() async => products;
}

void main() {
  testWidgets('shopper can open the product grid from home',
      (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(catalogService: _FakeCatalogService()));
    await tester.pumpAndSettle();

    expect(find.text('FrenzyBees'), findsOneWidget);
    expect(find.text('Shop the whole hive of deals'), findsOneWidget);
    expect(find.text('Browse the hive'), findsOneWidget);

    await tester.tap(find.text('Start shopping'));
    await tester.pumpAndSettle();

    expect(find.text('All products'), findsOneWidget);
    expect(find.text('Sneakers'), findsOneWidget);
  });

  testWidgets('shopper can search within a category',
      (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(catalogService: _FakeCatalogService()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Electronics').first);
    await tester.tap(find.text('Electronics').first);
    await tester.pumpAndSettle();

    expect(find.text('Headphones'), findsOneWidget);
    expect(find.text('Smartphone'), findsOneWidget);
  });

  testWidgets('shopper can reach add to cart from product detail',
      (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(catalogService: _FakeCatalogService()));
    await tester.pumpAndSettle();

    Navigator.of(tester.element(find.text('FrenzyBees'))).pushNamed(
      '/productDetail',
      arguments: products.first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Add to Cart'), findsOneWidget);
  });
}
