import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Borderless single-line field for composer / flat forms; uses typography + spacing, not boxes.
class MinimalTextField extends StatelessWidget {
  const MinimalTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.style,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.enabled = true,
    this.showBottomDivider = true,
    this.minLines,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final TextStyle? style;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool showBottomDivider;
  final int? minLines;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hintStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextField(
          controller: controller,
          enabled: enabled,
          onChanged: onChanged,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          minLines: minLines,
          maxLines: maxLines,
          style: style ?? Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: hintStyle,
            isDense: true,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (showBottomDivider) ...[
          const SizedBox(height: AppSpacing.sm),
          Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.45)),
        ],
      ],
    );
  }
}
