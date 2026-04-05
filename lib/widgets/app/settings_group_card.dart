import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../settings/settings_section_header.dart';

/// Rounded group container with optional [SettingsSectionHeader] above [child].
class SettingsGroupCard extends StatelessWidget {
  const SettingsGroupCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppInsets.screenPadding),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null && title!.isNotEmpty)
              SettingsSectionHeader(
                title: title!,
                subtitle: subtitle,
                trailing: trailing,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  subtitle != null && subtitle!.isNotEmpty ? AppSpacing.sm : AppSpacing.md,
                ),
              ),
            Padding(
              padding: padding ?? EdgeInsets.zero,
              child: Material(
                color: scheme.surfaceContainerLow,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
