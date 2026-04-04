import 'package:flutter/material.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

class SettingsGridCard extends StatelessWidget {
  const SettingsGridCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: scheme.surfaceContainerLow.withValues(alpha: 0.92),
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: BorderSide(
          color: scheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        splashColor: scheme.primary.withValues(alpha: 0.08),
        highlightColor: scheme.primary.withValues(alpha: 0.04),
        child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Icon(icon, size: 22, color: scheme.primary),
                    ),
                    const Spacer(),
                    if (trailing != null) trailing!,
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }
}
