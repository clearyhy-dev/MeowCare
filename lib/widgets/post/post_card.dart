import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/app_language_display.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/topic_l10n.dart';
import '../../models/post_model.dart';
import 'post_action_bar.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onOpenPost,
    this.onCommentTap,
  });

  final PostModel post;
  final VoidCallback onOpenPost;
  /// Defaults to [onOpenPost] if null. Use `?focusComment=1` on detail route to open keyboard on composer.
  final VoidCallback? onCommentTap;

  static String _formatTime(DateTime? t) {
    if (t == null) return '';
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat.MMMd().format(t);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasCategory = post.topics.isNotEmpty;
    return InkWell(
      onTap: onOpenPost,
      child: Container(
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
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(Icons.pets_rounded, size: 14, color: scheme.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'MeowCare',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                Text(
                  _formatTime(post.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _TagChip(text: AppLanguageDisplay.chipLabel(post.language, context.l10n)),
                if (hasCategory) _TagChip(text: feedTopicCategoryLabel(context, post.topics.first)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              post.title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
            ),
            if (post.content.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                post.content.trim(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (post.shouldShowImage) ...[
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    post.displayImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: scheme.surfaceContainerHighest,
                      child: Icon(Icons.broken_image_outlined, color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            PostActionBar(
              postId: post.postId,
              title: post.title,
              likeCount: post.likeCount,
              downvoteCount: post.downvoteCount,
              commentCount: post.commentCount,
              onCommentTap: onCommentTap ?? onOpenPost,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}
