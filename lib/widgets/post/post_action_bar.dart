import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/l10n_ext.dart';
import '../../core/utils/meow_share.dart';
import '../../core/utils/app_feedback.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/like_provider.dart';
import '../../providers/user_provider.dart';

class PostActionBar extends ConsumerWidget {
  const PostActionBar({
    super.key,
    required this.postId,
    required this.title,
    required this.likeCount,
    required this.downvoteCount,
    required this.commentCount,
    this.onCommentTap,
    this.compact = false,
  });

  final String postId;
  final String title;
  final int likeCount;
  final int downvoteCount;
  final int commentCount;
  final VoidCallback? onCommentTap;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserAsyncProvider).valueOrNull;
    final myVote = ref.watch(myEffectiveVoteProvider(postId));
    final voteUi = ref.watch(voteUiStateProvider(postId));
    final isBookmarked = ref.watch(isBookmarkedProvider(postId)).valueOrNull ?? false;
    final up = likeCount + (voteUi?.upDelta ?? 0);
    final down = downvoteCount + (voteUi?.downDelta ?? 0);
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(compact ? 12 : 14);
    final vPadding = compact ? 2.0 : 4.0;

    Future<void> requireLogin(Future<void> Function() action) async {
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.signInForFullFeatures)),
        );
        return;
      }
      await AppFeedback.lightTap();
      await action();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 4, vertical: vPadding),
      decoration: BoxDecoration(
        borderRadius: radius,
        color: scheme.surfaceContainerLow.withValues(alpha: 0.8),
      ),
      child: Row(
        children: [
          _ActionPill(
            icon: Icons.arrow_upward_rounded,
            label: '${up < 0 ? 0 : up}',
            selected: myVote == 1,
            selectedColor: scheme.primary,
            onPressed: () => requireLogin(() => toggleUpvote(ref, postId)),
          ),
          const SizedBox(width: 4),
          _ActionPill(
            icon: Icons.arrow_downward_rounded,
            label: '${down < 0 ? 0 : down}',
            selected: myVote == -1,
            selectedColor: scheme.error,
            onPressed: () => requireLogin(() => toggleDownvote(ref, postId)),
          ),
          const SizedBox(width: 4),
          _ActionPill(
            icon: Icons.chat_bubble_outline_rounded,
            label: '$commentCount',
            onPressed: onCommentTap,
          ),
          const Spacer(),
          _ActionPill(
            icon: isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
            label: '',
            selected: isBookmarked,
            selectedColor: scheme.primary,
            onPressed: () => requireLogin(() => toggleBookmark(ref, postId)),
          ),
          const SizedBox(width: 4),
          _ActionPill(
            icon: Icons.share_outlined,
            label: '',
            onPressed: () {
              AppFeedback.lightTap();
              MeowShare.sharePost(context, postId: postId, title: title);
            },
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.selectedColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? (selectedColor ?? scheme.primary) : scheme.onSurfaceVariant;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
            ],
          ],
        ),
      ),
    );
  }
}
