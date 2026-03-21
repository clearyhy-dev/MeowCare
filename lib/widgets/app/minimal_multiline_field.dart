import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Borderless multiline field for notes / body; relies on min/max lines and section spacing.
class MinimalMultilineField extends StatelessWidget {
  const MinimalMultilineField({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.style,
    this.minLines = 3,
    this.maxLines = 8,
    this.onChanged,
    this.enabled = true,
    this.showBottomDivider = true,
  });

  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final TextStyle? style;
  final int minLines;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool showBottomDivider;

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
          minLines: minLines,
          maxLines: maxLines,
          style: style ?? Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: hintStyle,
            alignLabelWithHint: true,
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
