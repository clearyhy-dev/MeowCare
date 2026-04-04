import 'package:flutter/material.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    this.title,
    this.secondary,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String message;
  final String? title;
  final String? secondary;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 38, color: scheme.onSurfaceVariant),
            const SizedBox(height: 10),
            if (title != null && title!.isNotEmpty) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (secondary != null && secondary!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                secondary!,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.9)),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 14),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
