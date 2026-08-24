import 'package:flutter/material.dart';

import 'app_nav_bar.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final bool showNavLinks;

  const AppScaffold({super.key, required this.body, this.showNavLinks = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          AppNavBar(showLinks: showNavLinks),
          Expanded(child: SingleChildScrollView(child: body)),
        ],
      ),
    );
  }
}
