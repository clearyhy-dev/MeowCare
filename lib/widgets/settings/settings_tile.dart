import 'package:flutter/material.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// Lightweight settings row (no heavy Card).
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.leading,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.useScreenHorizontalPadding = true,
  });

  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final bool useScreenHorizontalPadding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: useScreenHorizontalPadding ? AppInsets.screenPadding : 0,
      ),
      child: Material(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadii.sm + 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.sm + 2),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md + 2,
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: titleColor ?? scheme.onSurface,
                        ),
                      ),
                      if (subtitleWidget != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: DefaultTextStyle.merge(
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ) ?? const TextStyle(),
                            child: subtitleWidget!,
                          ),
                        )
                      else if (subtitle != null && subtitle!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle!,
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
