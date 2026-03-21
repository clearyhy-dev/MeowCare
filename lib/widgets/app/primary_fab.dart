import 'package:flutter/material.dart';

class PrimaryFab extends StatelessWidget {
  const PrimaryFab({
    super.key,
    required this.onPressed,
    required this.tooltip,
  });

  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 58,
      width: 58,
      child: FloatingActionButton(
        tooltip: tooltip,
        onPressed: onPressed,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        child: const Icon(Icons.add, size: 26),
      ),
    );
  }
}
