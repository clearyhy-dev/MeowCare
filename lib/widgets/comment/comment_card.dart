import 'package:flutter/material.dart';

import '../../models/comment_model.dart';

class CommentCard extends StatelessWidget {
  const CommentCard({
    super.key,
    required this.comment,
    required this.depth,
    required this.onReply,
    required this.replyLabel,
  });

  final CommentModel comment;
  final int depth;
  final VoidCallback onReply;
  final String replyLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final left = depth == 0 ? 0.0 : 14.0;
    return Padding(
      padding: EdgeInsets.only(left: left, bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.22)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (depth == 0)
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: (comment.authorPhotoUrl != null && comment.authorPhotoUrl!.isNotEmpty)
                          ? NetworkImage(comment.authorPhotoUrl!)
                          : null,
                      child: (comment.authorPhotoUrl == null || comment.authorPhotoUrl!.isEmpty)
                          ? const Icon(Icons.person, size: 14)
                          : null,
                    ),
                  if (depth == 0) const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      comment.displayAuthorLabel,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: onReply,
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: Text(replyLabel),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                comment.content,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (comment.replyToAuthor != null && comment.replyToAuthor!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '@${comment.replyToAuthor}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.primary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
