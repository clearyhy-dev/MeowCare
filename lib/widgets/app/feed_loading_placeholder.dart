import 'package:flutter/material.dart';

import 'skeleton_shimmer.dart';

/// Shimmer skeleton list for feed first paint (3–5 blocks).
class FeedLoadingPlaceholder extends StatelessWidget {
  const FeedLoadingPlaceholder({
    super.key,
    this.count = 4,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          count,
          (_) => const SkeletonPostCardBlock(),
        ),
      ),
    );
  }
}
