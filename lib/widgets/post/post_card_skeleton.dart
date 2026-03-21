import 'package:flutter/material.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final blockColor = scheme.surfaceContainerHighest.withValues(alpha: 0.7);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
