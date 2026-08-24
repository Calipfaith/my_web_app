import 'package:flutter/material.dart';

class UnderConstructionPage extends StatelessWidget {
  const UnderConstructionPage({super.key});

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFF5A623);
    const cream = Color(0xFFFFF8E7);
    return Scaffold(
      backgroundColor: cream,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/frenzybees_logo.png', width: 112, height: 112),
                const SizedBox(height: 24),
                const Text(
                  'FrenzyBees',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                const Text(
                  'We are getting the hive ready.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Our shop is currently under construction. Please check back soon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Color(0xFF5D5546)),
                ),
                const SizedBox(height: 28),
                Container(
                  height: 5,
                  width: 120,
                  decoration: BoxDecoration(
                    color: amber,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}