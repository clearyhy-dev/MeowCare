import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/l10n_ext.dart';
import '../../models/post_model.dart';
import '../../providers/feed_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app/app_empty_state.dart';
import '../../widgets/post/post_card.dart';

class MyPostsPage extends ConsumerStatefulWidget {
  const MyPostsPage({super.key});

  @override
  ConsumerState<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends ConsumerState<MyPostsPage> {
  static const List<String> _statuses = ['draft', 'pending', 'published', 'rejected'];
  String _status = 'published';
  final List<PostModel> _posts = [];
  DocumentSnapshot? _lastDoc;
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFirst());
  }

  Future<void> _loadFirst() async {
    final uid = ref.read(currentUserAsyncProvider).valueOrNull?.uid;
    if (uid == null) return;
    setState(() {
      _posts.clear();
      _lastDoc = null;
      _hasMore = true;
      _loading = true;
    });
    try {
      final repo = ref.read(postRepositoryProvider);
      final page = await repo.getMyPosts(authorId: uid, status: _status, limit: AppConstants.feedPageSize);
      if (!mounted) return;
      setState(() {
        _posts.addAll(page.list);
        _lastDoc = page.lastDoc;
        _hasMore = page.lastDoc != null;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore || _lastDoc == null) return;
    final uid = ref.read(currentUserAsyncProvider).valueOrNull?.uid;
    if (uid == null) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(postRepositoryProvider);
      final page = await repo.getMyPosts(
        authorId: uid,
        status: _status,
        limit: AppConstants.feedPageSize,
        startAfter: _lastDoc,
      );
      if (!mounted) return;
      setState(() {
        _posts.addAll(page.list);
        _lastDoc = page.lastDoc;
        _hasMore = page.lastDoc != null;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _statusLabel(BuildContext context, String s) {
    final l = context.l10n;
    switch (s) {
      case 'draft':
        return l.postStatusDraft;
      case 'pending':
        return l.postStatusPending;
      case 'published':
        return l.postStatusPublished;
      case 'rejected':
        return l.postStatusRejected;
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserAsyncProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.myPostsTitle),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: user == null
          ? AppEmptyState(message: context.l10n.signInForFullFeatures, icon: Icons.lock_outline_rounded)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<String>(
                      segments: _statuses
                          .map((s) => ButtonSegment<String>(value: s, label: Text(_statusLabel(context, s))))
                          .toList(),
                      selected: {_status},
                      onSelectionChanged: (selection) {
                        setState(() => _status = selection.first);
                        _loadFirst();
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: _posts.isEmpty && !_loading
                      ? AppEmptyState(message: context.l10n.myPostsEmpty, icon: Icons.article_outlined)
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: _posts.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _posts.length) {
                              _loadMore();
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final post = _posts[index];
                            return PostCard(
                              post: post,
                              onOpenPost: () => context.push('${AppRouter.home}post/${post.postId}'),
                              onCommentTap: () =>
                                  context.push('${AppRouter.home}post/${post.postId}?focusComment=1'),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
