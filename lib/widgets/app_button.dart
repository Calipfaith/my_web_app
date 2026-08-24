import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool amber;

  const AppButton({super.key, required this.label, required this.onPressed, this.amber = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: amber ? scheme.primary : scheme.secondary,
        foregroundColor: amber ? scheme.onPrimary : scheme.surface,
      ),
      child: Text(label),
    );
  }
}
