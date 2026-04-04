import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/l10n_ext.dart';
import '../../models/comment_model.dart';
import '../../providers/comment_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app/app_empty_state.dart';
import '../../widgets/app/skeleton_shimmer.dart';

class MyCommentsPage extends ConsumerStatefulWidget {
  const MyCommentsPage({super.key});

  @override
  ConsumerState<MyCommentsPage> createState() => _MyCommentsPageState();
}

class _MyCommentsPageState extends ConsumerState<MyCommentsPage> {
  final List<CommentModel> _comments = [];
  final Map<String, String> _postTitles = {};
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
      _comments.clear();
      _postTitles.clear();
      _lastDoc = null;
      _hasMore = true;
      _loading = true;
    });
    try {
      final repo = ref.read(commentRepositoryProvider);
      final page = await repo.getMyCommentsWithPostTitles(
        authorId: uid,
        limit: AppConstants.feedPageSize,
      );
      if (!mounted) return;
      setState(() {
        _comments.addAll(page.comments);
        _postTitles.addAll(page.postTitles);
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
      final repo = ref.read(commentRepositoryProvider);
      final page = await repo.getMyCommentsWithPostTitles(
        authorId: uid,
        limit: AppConstants.feedPageSize,
        startAfter: _lastDoc,
      );
      if (!mounted) return;
      setState(() {
        _comments.addAll(page.comments);
        _postTitles.addAll(page.postTitles);
        _lastDoc = page.lastDoc;
        _hasMore = page.lastDoc != null;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserAsyncProvider).valueOrNull;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.myCommentsTitle),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: user == null
          ? AppEmptyState(message: context.l10n.signInForFullFeatures, icon: Icons.lock_outline_rounded)
          : _loading && _comments.isEmpty
              ? ShimmerScope(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    children: const [
                      SkeletonNotificationTile(),
                      SizedBox(height: AppSpacing.sm),
                      SkeletonNotificationTile(),
                      SizedBox(height: AppSpacing.sm),
                      SkeletonNotificationTile(),
                      SizedBox(height: AppSpacing.sm),
                      SkeletonNotificationTile(),
                    ],
                  ),
                )
              : _comments.isEmpty && !_loading
                  ? AppEmptyState(message: context.l10n.myCommentsEmpty, icon: Icons.chat_bubble_outline)
                  : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  itemCount: _comments.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _comments.length) {
                      _loadMore();
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final c = _comments[index];
                    final title = _postTitles[c.postId] ?? context.l10n.postTitleUnknown;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Material(
                        color: scheme.surfaceContainerLow.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          onTap: () {
                            final q = c.parentCommentId != null && c.parentCommentId!.isNotEmpty
                                ? '?focusComment=1'
                                : '';
                            context.push('${AppRouter.home}post/${c.postId}$q');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  c.content,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
