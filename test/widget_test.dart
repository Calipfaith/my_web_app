// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:my_web_app/main.dart';

void main() {
  testWidgets('shopper can open the product grid from home',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Shop by category'), findsOneWidget);
    expect(find.text('Men'), findsOneWidget);

    await tester.tap(find.text('Men'));
    await tester.pumpAndSettle();

    expect(find.text('Men'), findsOneWidget);
    expect(find.text('Sneakers'), findsOneWidget);
    expect(find.text('Smartphone'), findsNothing);
  });
}
