import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Semantic button variants for consistent CTAs across the app.
enum AppButtonVariant {
  primary,
  secondary,
  ghost,
  danger,
  small,
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final Widget? icon;

  bool get _disabled => loading || onPressed == null;

  @override
  Widget build(BuildContext context) {
    final isSmall = variant == AppButtonVariant.small;
    final height = isSmall ? 36.0 : 48.0;
    final hPad = isSmall ? AppSpacing.md : AppSpacing.xl;
    final vPad = isSmall ? 8.0 : 12.0;

    final child = loading
        ? SizedBox(
            height: isSmall ? 18 : 22,
            width: isSmall ? 18 : 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _spinnerColor(context),
            ),
          )
        : _buildLabel(context, isSmall);

    VoidCallback? handler = _disabled ? null : onPressed;

    switch (variant) {
      case AppButtonVariant.primary:
        return FilledButton(
          onPressed: handler,
          style: FilledButton.styleFrom(
            minimumSize: Size.fromHeight(height),
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: child,
        );
      case AppButtonVariant.secondary:
        return OutlinedButton(
          onPressed: handler,
          style: OutlinedButton.styleFrom(
            minimumSize: Size.fromHeight(height),
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: child,
        );
      case AppButtonVariant.ghost:
      case AppButtonVariant.small:
        return TextButton(
          onPressed: handler,
          style: TextButton.styleFrom(
            minimumSize: Size.fromHeight(height),
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: variant == AppButtonVariant.small
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          child: child,
        );
      case AppButtonVariant.danger:
        return TextButton(
          onPressed: handler,
          style: TextButton.styleFrom(
            minimumSize: Size.fromHeight(height),
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            foregroundColor: Theme.of(context).colorScheme.error,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: child,
        );
    }
  }

  Color? _spinnerColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (variant) {
      case AppButtonVariant.primary:
        return scheme.onPrimary;
      case AppButtonVariant.secondary:
        return scheme.primary;
      case AppButtonVariant.danger:
        return scheme.error;
      default:
        return scheme.primary;
    }
  }

  Widget _buildLabel(BuildContext context, bool isSmall) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: isSmall ? 13 : null,
        );
    if (icon == null) {
      return Text(label, style: style);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconTheme.merge(
          data: IconThemeData(size: isSmall ? 18 : 20),
          child: icon!,
        ),
        SizedBox(width: isSmall ? 6 : 8),
        Text(label, style: style),
      ],
    );
  }
}

enum AppIconButtonSize { standard, dense }

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = AppIconButtonSize.standard,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final AppIconButtonSize size;

  @override
  Widget build(BuildContext context) {
    final dim = size == AppIconButtonSize.dense ? 40.0 : 44.0;
    final iconSize = size == AppIconButtonSize.dense ? 20.0 : 22.0;
    final scheme = Theme.of(context).colorScheme;

    Widget btn = Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: dim,
          height: dim,
          child: Icon(icon, size: iconSize, color: scheme.onSurface),
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      btn = Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}
