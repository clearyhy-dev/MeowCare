import 'package:flutter/material.dart';

import '../../core/theme/app_radii.dart';

/// Subtle numeric badge for settings / hub tiles (e.g. unread count).
class SettingsBadge extends StatelessWidget {
  const SettingsBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final label = count > 99 ? '99+' : '$count';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              height: 1,
            ),
      ),
    );
  }
}
