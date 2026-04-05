import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../app/app_surface_card.dart';
import 'feed_mode_switcher.dart';
import 'feed_search_field.dart';

class FeedControlBar extends StatelessWidget {
  const FeedControlBar({
    super.key,
    required this.searchController,
    required this.searchHintText,
    required this.onSearchChanged,
    required this.latestSelected,
    required this.latestLabel,
    required this.hotLabel,
    required this.onSelectLatest,
    required this.onSelectHot,
  });

  final TextEditingController searchController;
  final String searchHintText;
  final ValueChanged<String> onSearchChanged;
  final bool latestSelected;
  final String latestLabel;
  final String hotLabel;
  final VoidCallback onSelectLatest;
  final VoidCallback onSelectHot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.feedGutter, AppSpacing.sm, AppSpacing.feedGutter, AppSpacing.md),
      child: AppSurfaceCard(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
        showShadow: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FeedSearchField(
              controller: searchController,
              hintText: searchHintText,
              onChanged: onSearchChanged,
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: FeedModeSwitcher(
                latestSelected: latestSelected,
                latestLabel: latestLabel,
                hotLabel: hotLabel,
                onSelectLatest: onSelectLatest,
                onSelectHot: onSelectHot,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
