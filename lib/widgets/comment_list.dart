import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/l10n_ext.dart';
import '../providers/comment_provider.dart';
import '../models/comment_model.dart';


class CommentList extends ConsumerStatefulWidget {
  const CommentList({
    super.key,
    required this.postId,
    this.currentUid,
    required this.onCommentAdded,
    this.currentUserDisplayName,
    this.currentUserPhotoUrl,
  });

  final String postId;
  final String? currentUid;
  final VoidCallback onCommentAdded;
  /// 当前登录用户显示名（发评论时写入，列表显示为“Google 账号/昵称”）
  final String? currentUserDisplayName;
  /// 当前用户头像 URL
  final String? currentUserPhotoUrl;

  @override
  ConsumerState<CommentList> createState() => _CommentListState();
}

class _CommentListState extends ConsumerState<CommentList> {
  final _contentController = TextEditingController();
  List<CommentModel> _comments = [];
  DocumentSnapshot? _lastDoc;
  bool _loading = false;
  bool _hasMore = true;

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
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFirst();
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;
    final currentUid = widget.currentUid;
    if (currentUid == null || currentUid.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.signInForFullFeatures)),
        );
      }
      return;
    }
    _contentController.clear();
    try {
      await ref.read(commentRepositoryProvider).addComment(
            postId: widget.postId,
            authorId: currentUid,
            content: content,
            authorDisplayName: widget.currentUserDisplayName,
            authorPhotoUrl: widget.currentUserPhotoUrl,
          );
      widget.onCommentAdded();
      _loadFirst();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithMessage(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _contentController,
          enabled: (widget.currentUid ?? '').isNotEmpty,
          decoration: InputDecoration(
            hintText: (widget.currentUid ?? '').isNotEmpty ? context.l10n.comments : context.l10n.signInForFullFeatures,
            suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: _submit),
            border: const OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        if (_loading && _comments.isEmpty)
          const Center(child: CircularProgressIndicator())
        else
          ..._comments.map((c) => ListTile(
                leading: CircleAvatar(
                  backgroundImage: (c.authorPhotoUrl != null && c.authorPhotoUrl!.isNotEmpty)
                      ? NetworkImage(c.authorPhotoUrl!)
                      : null,
                  child: (c.authorPhotoUrl == null || c.authorPhotoUrl!.isEmpty)
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(c.content),
                subtitle: Text(c.displayAuthorLabel),
              )),
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
}

