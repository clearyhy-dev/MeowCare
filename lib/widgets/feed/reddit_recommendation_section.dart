import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/l10n_ext.dart';
import '../../models/post_model.dart';
import '../../providers/feed_provider.dart';
import '../app/app_section_header.dart';
import '../app/app_surface_card.dart';

/// Reddit 热门横滑模块（与 Feed 列表解耦，便于复用样式）。
class RedditRecommendationSection extends ConsumerWidget {
  const RedditRecommendationSection({
    super.key,
    required this.onTapPost,
  });

  final void Function(String postId) onTapPost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(redditTrendingProvider);
    return async.when(
      data: (posts) {
        if (posts.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.feedGutter, 0, AppSpacing.feedGutter, AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSectionHeader(
                title: context.l10n.trendingCatsFromReddit,
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              ),
              SizedBox(
                height: 112,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, i) => _RedditMiniCard(
                    post: posts[i],
                    onTap: () => onTapPost(posts[i].postId),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _RedditMiniCard extends StatelessWidget {
  const _RedditMiniCard({
    required this.post,
    required this.onTap,
  });

  final PostModel post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final thumb = post.displayImageUrl.trim();
    final radius = BorderRadius.circular(AppRadii.md);
    return SizedBox(
      width: 208,
      child: AppSurfaceCard(
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        showShadow: false,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(AppRadii.md)),
                  child: SizedBox(
                    width: 88,
                    child: thumb.isNotEmpty
                        ? Image.network(
                            thumb,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => ColoredBox(
                              color: scheme.surfaceContainerHighest,
                              child: Icon(Icons.image_not_supported_outlined, color: scheme.onSurfaceVariant),
                            ),
                          )
                        : ColoredBox(
                            color: scheme.surfaceContainerHighest,
                            child: Icon(Icons.pets_rounded, color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                          ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          post.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          context.l10n.sourceReddit,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
