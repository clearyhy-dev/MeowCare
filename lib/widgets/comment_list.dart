import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/l10n_ext.dart';
import '../providers/comment_provider.dart';
import '../models/comment_model.dart';
import 'app/empty_state_view.dart';
import 'comment/comment_card.dart';
import 'comment/comment_composer.dart';


class CommentList extends ConsumerStatefulWidget {
  const CommentList({
    super.key,
    required this.postId,
    this.currentUid,
    required this.onCommentAdded,
    this.currentUserDisplayName,
    this.currentUserPhotoUrl,
    this.commentFocusNode,
    this.scrollToCommentId,
  });

  final String postId;
  final String? currentUid;
  final VoidCallback onCommentAdded;
  /// 当前登录用户显示名（发评论时写入，列表显示为“Google 账号/昵称”）
  final String? currentUserDisplayName;
  /// 当前用户头像 URL
  final String? currentUserPhotoUrl;
  final FocusNode? commentFocusNode;
  /// 首屏加载完成后滚动到该评论（通知深链）；不在首屏分页内则忽略。
  final String? scrollToCommentId;

  @override
  ConsumerState<CommentList> createState() => _CommentListState();
}

class _CommentListState extends ConsumerState<CommentList> {
  final _contentController = TextEditingController();
  List<CommentModel> _comments = [];
  DocumentSnapshot? _lastDoc;
  bool _loading = false;
  bool _hasMore = true;
  CommentModel? _replyTarget;
  final Set<String> _expandedReplyParents = <String>{};
  bool _submitting = false;
  final Map<String, GlobalKey> _commentAnchorKeys = {};
  bool _didScrollToHighlight = false;

  GlobalKey _anchorKeyFor(String commentId) =>
      _commentAnchorKeys.putIfAbsent(commentId, () => GlobalKey(debugLabel: 'comment_$commentId'));

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadFirst() async {
    setState(() => _loading = true);
    final result = await ref.read(commentRepositoryProvider).getComments(
          postId: widget.postId,
          limit: AppConstants.feedPageSize,
        );
    if (mounted) {
      setState(() {
        _comments = result.list;
        _lastDoc = result.lastDoc;
        _hasMore = result.list.length == AppConstants.feedPageSize;
        _loading = false;
      });
      _scheduleScrollToHighlight();
    }
  }

  void _expandAncestorsOf(CommentModel target) {
    var pid = target.parentCommentId;
    while (pid != null && pid.isNotEmpty) {
      _expandedReplyParents.add(pid);
      CommentModel? parent;
      for (final c in _comments) {
        if (c.commentId == pid) {
          parent = c;
          break;
        }
      }
      pid = parent?.parentCommentId;
    }
  }

  void _scheduleScrollToHighlight() {
    final id = widget.scrollToCommentId?.trim();
    if (id == null || id.isEmpty || _didScrollToHighlight) return;

    CommentModel? target;
    for (final c in _comments) {
      if (c.commentId == id) {
        target = c;
        break;
      }
    }
    if (target == null) return;

    setState(() => _expandAncestorsOf(target!));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx = _anchorKeyFor(id).currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.15,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
          );
          _didScrollToHighlight = true;
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _loadFirst();
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty || _submitting) return;
    final currentUid = widget.currentUid;
    if (currentUid == null || currentUid.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.signInForFullFeatures)),
        );
      }
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(commentRepositoryProvider).addComment(
            postId: widget.postId,
            authorId: currentUid,
            content: content,
            authorDisplayName: widget.currentUserDisplayName,
            authorPhotoUrl: widget.currentUserPhotoUrl,
            parentCommentId: _replyTarget?.commentId,
            replyToAuthor: _replyTarget?.displayAuthorLabel,
          );
      if (!mounted) return;
      _contentController.clear();
      widget.onCommentAdded();
      setState(() => _replyTarget = null);
      await _loadFirst();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithMessage(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topLevel = _comments.where((c) => (c.parentCommentId == null || c.parentCommentId!.isEmpty)).toList();
    final childrenMap = <String, List<CommentModel>>{};
    for (final c in _comments) {
      final pid = c.parentCommentId;
      if (pid == null || pid.isEmpty) continue;
      childrenMap.putIfAbsent(pid, () => <CommentModel>[]).add(c);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_replyTarget != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.replyToUser(_replyTarget!.displayAuthorLabel),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _replyTarget = null),
                ),
              ],
            ),
          ),
        CommentComposer(
          controller: _contentController,
          enabled: (widget.currentUid ?? '').isNotEmpty,
          onSubmit: _submit,
          focusNode: widget.commentFocusNode,
          onTap: widget.commentFocusNode != null ? () => widget.commentFocusNode!.requestFocus() : null,
          isSubmitting: _submitting,
        ),
        const SizedBox(height: 16),
        if (_loading && _comments.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (!_loading && topLevel.isEmpty)
          EmptyStateView(
            title: context.l10n.commentsEmptyTitle,
            message: context.l10n.commentsEmptyBody,
            icon: Icons.chat_bubble_outline_rounded,
          )
        else
          ...topLevel.map((c) => _buildCommentNode(context, c, 0, childrenMap)),
        if (_hasMore && _comments.isNotEmpty)
          TextButton(
            onPressed: () async {
              if (_lastDoc == null) return;
              setState(() => _loading = true);
              final result = await ref.read(commentRepositoryProvider).getComments(
                    postId: widget.postId,
                    limit: AppConstants.feedPageSize,
                    startAfter: _lastDoc,
                  );
              if (mounted) {
                setState(() {
                  _comments = [..._comments, ...result.list];
                  _lastDoc = result.lastDoc;
                  _hasMore = result.list.length == AppConstants.feedPageSize;
                  _loading = false;
                });
              }
            },
            child: Text(context.l10n.loadMore),

          ),
      ],
    );
  }

  Widget _buildCommentNode(
    BuildContext context,
    CommentModel comment,
    int depth,
    Map<String, List<CommentModel>> childrenMap,
  ) {
    final replies = childrenMap[comment.commentId] ?? const <CommentModel>[];
    final isExpanded = _expandedReplyParents.contains(comment.commentId);
    final visibleReplies = (isExpanded || replies.length <= 3) ? replies : replies.take(3).toList();
    final leftPad = depth == 0 ? 0.0 : (16.0 * depth);

    return Padding(
      key: _anchorKeyFor(comment.commentId),
      padding: EdgeInsets.only(left: leftPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CommentCard(
            comment: comment,
            depth: depth,
            onReply: () => setState(() => _replyTarget = comment),
            replyLabel: context.l10n.replyAction,
          ),
          ...visibleReplies.map((reply) => _buildCommentNode(context, reply, depth + 1, childrenMap)),
          if (replies.length > 3)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedReplyParents.remove(comment.commentId);
                      } else {
                        _expandedReplyParents.add(comment.commentId);
                      }
                    });
                  },
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                  ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isExpanded
                            ? context.l10n.collapseReplies
                            : context.l10n.viewMoreReplies(replies.length - 3),
                      ),
                      if (!isExpanded) ...[
                        const SizedBox(width: 6),
                        Text(
                          '+${replies.length - 3}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

