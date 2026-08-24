import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../services/auth_service.dart';

class AppNavBar extends StatelessWidget {
  final bool showLinks;

  const AppNavBar({super.key, this.showLinks = true});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cartCount = context.watch<CartProvider>().items.length;
    final wide = MediaQuery.of(context).size.width > 900;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant, width: .5),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/frenzybees_logo.png',
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Text(
            'FrenzyBees',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: scheme.secondary,
            ),
          ),
          if (wide && showLinks)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final label in ['New', 'Categories', 'Deals', 'About'])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            )
          else
            const Spacer(),
          if (wide && showLinks && AuthService.accessToken != null)
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/queen'),
              child: const Text('Queen Storefront'),
            ),
          if (wide && showLinks && AuthService.isQueen)
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/queen/dashboard'),
              child: const Text('Dashboard'),
            ),
          IconButton(
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 36),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 36),
            icon: const Icon(Icons.favorite_border),
          ),
          TextButton(
            onPressed: () => AuthService.accessToken == null
                ? Navigator.pushNamed(context, '/login')
                : Navigator.pushNamed(context, '/profile'),
            style: TextButton.styleFrom(
              foregroundColor: scheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              AuthService.accessToken == null
                  ? 'Sign in'
                  : (AuthService.displayName ?? 'Profile'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (AuthService.accessToken != null)
            IconButton(
              tooltip: 'Sign out',
              onPressed: () async {
                try {
                  await AuthService().revokeSession();
                } finally {
                  if (context.mounted)
                    Navigator.pushReplacementNamed(context, '/login');
                }
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36),
              icon: const Icon(Icons.logout),
            ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () => Navigator.pushNamed(context, '/cart'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 36),
                icon: const Icon(Icons.shopping_bag_outlined),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: scheme.primary,
                    child: Text(
                      '$cartCount',
                      style: TextStyle(fontSize: 10, color: scheme.onPrimary),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
