import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'app_empty_state.dart';

/// [AppEmptyState] with configurable padding and optional [SingleChildScrollView] for [RefreshIndicator] nesting.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.message,
    this.title,
    this.secondary,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.useScrollView = false,
    this.padding,
  });

  final String message;
  final String? title;
  final String? secondary;
  final IconData icon;
  final Widget? action;
  final bool useScrollView;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final inner = AppEmptyState(
      message: message,
      title: title,
      secondary: secondary,
      icon: icon,
      action: action,
    );
    final padded = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.xl),
      child: inner,
    );
    if (useScrollView) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: padded,
            ),
          );
        },
      );
    }
    return padded;
  }
}
