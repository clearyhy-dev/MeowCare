import 'package:flutter/material.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

class _ShimmerData extends InheritedWidget {
  const _ShimmerData({
    required super.child,
    required this.t,
  });

  final double t;

  static double? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ShimmerData>()?.t;
  }

  @override
  bool updateShouldNotify(_ShimmerData oldWidget) => oldWidget.t != t;
}

/// Repeating shimmer; place once as ancestor of skeleton children.
class ShimmerScope extends StatefulWidget {
  const ShimmerScope({super.key, required this.child});

  final Widget child;

  @override
  State<ShimmerScope> createState() => _ShimmerScopeState();
}

class _ShimmerScopeState extends State<ShimmerScope> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return _ShimmerData(t: _controller.value, child: child!);
      },
      child: widget.child,
    );
  }
}

Color _baseColor(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return scheme.surfaceContainerHighest.withValues(alpha: 0.9);
}

Color _highlightColor(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return scheme.onSurface.withValues(alpha: 0.06);
}

class SkeletonLine extends StatelessWidget {
  const SkeletonLine({
    super.key,
    this.width,
    this.height = 12,
    this.radius = AppRadii.xs,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final t = _ShimmerData.of(context) ?? 0;
    final base = _baseColor(context);
    final hi = _highlightColor(context);
    final shift = (t * 2) - 1;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(shift - 1, 0),
              end: Alignment(shift + 1, 0),
              colors: [base, hi, base],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: Container(color: Colors.white),
        ),
      ),
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: SkeletonLine(width: size, height: size, radius: size / 2),
      ),
    );
  }
}

class SkeletonNotificationTile extends StatelessWidget {
  const SkeletonNotificationTile({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonCircle(size: 44),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: MediaQuery.sizeOf(context).width * 0.45, height: 14),
                const SizedBox(height: 8),
                SkeletonLine(width: double.infinity, height: 10),
                const SizedBox(height: 6),
                SkeletonLine(width: MediaQuery.sizeOf(context).width * 0.35, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonPostCardBlock extends StatelessWidget {
  const SkeletonPostCardBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonCircle(size: 36),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLine(width: 120, height: 12),
                      const SizedBox(height: 6),
                      SkeletonLine(width: 80, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SkeletonLine(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            SkeletonLine(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            SkeletonLine(width: 200, height: 14),
            const SizedBox(height: AppSpacing.lg),
            SkeletonLine(width: double.infinity, height: 160, radius: AppRadii.sm),
          ],
        ),
      ),
    );
  }
}
