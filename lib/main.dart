import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import your provider + pages
import 'providers/cart_provider.dart';
import 'pages/persona_page.dart';
import 'pages/home_page.dart' as home_page;
import 'pages/product_grid_page.dart';
import 'pages/product_detail_page.dart';
import 'pages/cart_page.dart';
import 'pages/checkout_page.dart';
import 'pages/payment_confirmation_page.dart';
import 'pages/order_tracking_page.dart';
import 'pages/login_page.dart';
import 'pages/order_history_page.dart';
import 'pages/under_construction_page.dart';
import 'pages/profile_page.dart';
import 'pages/queen_storefront_page.dart';
import 'pages/queen_dashboard_page.dart';
import 'pages/bee_dashboard_page.dart';
import 'pages/live_drop_page.dart';
import 'pages/partner_dashboard_page.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/investor_dashboard_page.dart';
import 'services/catalog_service.dart';
import 'services/auth_service.dart';

const underConstruction = bool.fromEnvironment(
  'UNDER_CONSTRUCTION',
  defaultValue: true,
);
const queenPreview = bool.fromEnvironment('QUEEN_PREVIEW', defaultValue: false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.restore();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final CatalogService catalogService;

  MyApp({super.key, CatalogService? catalogService})
    : catalogService = catalogService ?? CatalogService();

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFF5A623);
    const nearBlack = Color(0xFF2B2B2B);
    const cream = Color(0xFFFFF8E7);

    return ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        title: 'FrenzyBees',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme:
              ColorScheme.fromSeed(
                seedColor: amber,
                brightness: Brightness.light,
              ).copyWith(
                primary: amber,
                onPrimary: nearBlack,
                secondary: nearBlack,
                onSecondary: cream,
                surface: cream,
                background: cream,
                onSurface: nearBlack,
              ),
          scaffoldBackgroundColor: cream,
          appBarTheme: const AppBarTheme(
            backgroundColor: amber,
            foregroundColor: nearBlack,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: amber,
              foregroundColor: nearBlack,
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: amber,
            foregroundColor: nearBlack,
          ),
        ),
        initialRoute: Uri.base.queryParameters.containsKey('code')
            ? '/login'
            : Uri.base.queryParameters.containsKey('session_id')
            ? '/confirmation'
            : '/home',
        builder: (context, child) =>
            underConstruction &&
                !Uri.base.queryParameters.containsKey('code') &&
                !Uri.base.queryParameters.containsKey('session_id')
            ? const UnderConstructionPage()
            : child ?? const UnderConstructionPage(),
        routes: {
          '/': (context) => PersonaPage(),
          '/home': (context) => home_page.HomePage(),
          '/customer': (context) => home_page.HomePage(),
          '/productGrid': (context) =>
              ProductGridPage(catalogService: catalogService),
          '/productDetail': (context) => ProductDetailPage(),
          '/cart': (context) => CartPage(),
          '/checkout': (context) => CheckoutPage(),
          '/confirmation': (context) => PaymentConfirmationPage(),
          '/tracking': (context) => OrderTrackingPage(),
          '/login': (context) => LoginPage(),
          '/auth/login': (context) => LoginPage(),
          '/orders': (context) => OrderHistoryPage(),
          '/profile': (context) => ProfilePage(),
          '/queen': (context) => QueenStorefrontPage(),
          '/bee': (context) => AuthService.isBee || queenPreview
              ? BeeDashboardPage()
              : const UnderConstructionPage(),
          '/live': (context) => LiveDropPage(
            sessionId:
                ModalRoute.of(context)?.settings.arguments as String? ?? '',
          ),
          '/queen/dashboard': (context) => AuthService.isQueen || queenPreview
              ? QueenDashboardPage()
              : const UnderConstructionPage(),
          '/partner': (context) => const PartnerDashboardPage(),
          '/admin': (context) => const AdminDashboardPage(),
          '/investor': (context) => const InvestorDashboardPage(),
        },
      ),
    );
  }
}
