import 'package:flutter/material.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final blockColor = scheme.surfaceContainerHighest.withValues(alpha: 0.7);
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.md, 0, AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: scheme.outline.withValues(alpha: 0.18),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(width: 140, height: 12, color: blockColor),
          const SizedBox(height: 12),
          _line(width: double.infinity, height: 18, color: blockColor),
          const SizedBox(height: 8),
          _line(width: 220, height: 14, color: blockColor),
          const SizedBox(height: 12),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: blockColor,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _line(width: 58, height: 28, color: blockColor),
              const SizedBox(width: 6),
              _line(width: 58, height: 28, color: blockColor),
              const SizedBox(width: 6),
              _line(width: 58, height: 28, color: blockColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line({required double width, required double height, required Color color}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
