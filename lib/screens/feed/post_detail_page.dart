import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/app_language_display.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/topic_l10n.dart';
import '../../data/repositories/report_repository.dart';
import '../../models/post_model.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/feed_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app/app_button.dart';
import '../../widgets/app/app_section_header.dart';
import '../../widgets/app/error_state_view.dart';
import '../../widgets/app/tag_chip.dart';
import '../../widgets/app/skeleton_shimmer.dart';
import '../../widgets/comment_list.dart';
import '../../widgets/post/post_action_bar.dart';
import '../../widgets/post/post_media_carousel.dart';

class PostDetailPage extends ConsumerStatefulWidget {
  const PostDetailPage({
    super.key,
    required this.postId,
    this.focusCommentOnOpen = false,
    this.highlightCommentId,
  });

  final String postId;
  /// Opened from feed comment tap (`?focusComment=1`): scroll to composer and focus.
  final bool focusCommentOnOpen;
  /// 通知等深链：`?commentId=` 滚动到对应评论（与 [focusCommentOnOpen] 同时存在时优先滚动到评论，不弹键盘）。
  final String? highlightCommentId;

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  static const _kErrorPostNotFound = 'post_not_found';
  static const double _heroImageHeight = 160;

  final _scrollController = ScrollController();
  final _commentFocusNode = FocusNode();
  final GlobalKey _commentsHeaderKey = GlobalKey();
  bool _didAutoFocusComment = false;

  PostModel? _post;
  bool _loading = true;
  String? _error;

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final repo = ref.read(postRepositoryProvider);
      final post = await repo.getPost(widget.postId);
      if (!mounted) return;
      setState(() {
        _post = post;
        if (!silent) _loading = false;
        if (post == null) {
          _error = _kErrorPostNotFound;
        } else {
          _error = null;
        }
      });
      final highlight = widget.highlightCommentId?.trim() ?? '';
      if (post != null &&
          widget.focusCommentOnOpen &&
          highlight.isEmpty &&
          !_didAutoFocusComment) {
        _didAutoFocusComment = true;
        final uid = ref.read(currentUserAsyncProvider).valueOrNull?.uid ?? '';
        _scrollCommentsIntoViewAndFocus(requestKeyboard: uid.isNotEmpty);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (!silent) {
            _loading = false;
            _post = null;
          }
          _error = silent ? _error : e.toString();
        });
        if (silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errorGenericRetry)),
          );
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _scrollCommentsIntoViewAndFocus({required bool requestKeyboard}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final headerCtx = _commentsHeaderKey.currentContext;
      if (headerCtx != null) {
        Scrollable.ensureVisible(
          headerCtx,
          alignment: 0.1,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
      if (!requestKeyboard) return;
      Future<void>.delayed(const Duration(milliseconds: 320), () {
        if (mounted) _commentFocusNode.requestFocus();
      });
    });
  }

  void _onCommentShortcutPressed() {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final uid = ref.read(currentUserAsyncProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.signInForFullFeatures)));
      _scrollCommentsIntoViewAndFocus(requestKeyboard: false);
      return;
    }
    _scrollCommentsIntoViewAndFocus(requestKeyboard: true);
  }

  static String _formatTime(DateTime? t) {
    if (t == null) return '';
    return DateFormat.yMMMd().add_jm().format(t.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    if (_loading) {
      return Scaffold(
        backgroundColor: surface,
        appBar: AppBar(
          title: Text(context.l10n.post),
        ),
        body: const _PostDetailLoadingBody(),
      );
    }
    if (_post == null) {
      final notFound = _error == _kErrorPostNotFound;
      return Scaffold(
        backgroundColor: surface,
        appBar: AppBar(title: Text(context.l10n.post)),
        body: ErrorStateView(
          title: notFound ? context.l10n.postNotFound : context.l10n.errorGenericRetry,
          message: notFound ? null : (_error ?? context.l10n.notFound),
          onRetry: notFound ? null : _load,
          retryLabel: notFound ? null : context.l10n.retry,
        ),
      );
    }
    final post = _post!;
    final commentHighlightId = widget.highlightCommentId?.trim();
    final user = ref.watch(currentUserAsyncProvider).valueOrNull;
    final scheme = Theme.of(context).colorScheme;
    final onVar = scheme.onSurfaceVariant;
    final hasCategory = post.topics.isNotEmpty;

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        title: Text(context.l10n.post),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            onPressed: user == null ? null : () => _showReportDialog(context),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: PostActionBar(
          postId: widget.postId,
          title: post.title,
          likeCount: post.likeCount,
          downvoteCount: post.downvoteCount,
          commentCount: post.commentCount,
          onCommentTap: _onCommentShortcutPressed,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: scheme.primaryContainer,
                        child: Icon(Icons.pets_rounded, size: 18, color: scheme.primary),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          post.authorDisplayName.trim().isNotEmpty
                              ? post.authorDisplayName.trim()
                              : context.l10n.appTitle,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (_formatTime(post.createdAt).isNotEmpty)
                        Text(
                          _formatTime(post.createdAt),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: onVar),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      TagChip(text: AppLanguageDisplay.chipLabel(post.language, context.l10n)),
                      if (hasCategory) TagChip(text: feedTopicCategoryLabel(context, post.topics.first)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    post.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                  ),
                  if (post.linkUrl.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    InkWell(
                      onTap: () => _openUrl(post.linkUrl.trim()),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        child: Row(
                          children: [
                            Icon(Icons.link_rounded, size: 20, color: scheme.primary),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                post.linkUrl.trim(),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: scheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (post.shouldShowImage) ...[
                    const SizedBox(height: AppSpacing.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      child: post.mediaItems.isNotEmpty
                          ? PostMediaCarousel(
                              items: post.mediaItems,
                              borderRadius: BorderRadius.circular(AppRadii.md),
                              videoMuted: false,
                            )
                          : SizedBox(
                              height: _heroImageHeight,
                              width: double.infinity,
                              child: Image.network(
                                post.displayImageUrl,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  final total = progress.expectedTotalBytes;
                                  return ColoredBox(
                                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        value: total != null && total > 0
                                            ? progress.cumulativeBytesLoaded / total
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => ColoredBox(
                                  color: scheme.surfaceContainerHighest,
                                  child: Center(child: Icon(Icons.broken_image_outlined, size: 32, color: onVar)),
                                ),
                              ),
                            ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                  const SizedBox(height: AppSpacing.lg),
                  _linkedPostContent(context, post.displayBody),
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _onCommentShortcutPressed,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: AppSectionHeader(
                          key: _commentsHeaderKey,
                          title: '${context.l10n.comments} (${post.commentCount})',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CommentList(
                    postId: widget.postId,
                    currentUid: user?.uid,
                    onCommentAdded: () => _load(silent: true),
                    currentUserDisplayName: ((user?.displayName ?? '').isNotEmpty) ? user?.displayName : user?.email,
                    currentUserPhotoUrl: ((user?.photoUrl ?? '').isNotEmpty) ? user?.photoUrl : null,
                    commentFocusNode: _commentFocusNode,
                    scrollToCommentId:
                        (commentHighlightId != null && commentHighlightId.isNotEmpty) ? commentHighlightId : null,
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkedPostContent(BuildContext context, String text) {
    final baseStyle = Theme.of(context).textTheme.bodyLarge;
    final primary = Theme.of(context).colorScheme.primary;
    final urlRe = RegExp(r'https?://[^\s]+', caseSensitive: false);
    if (!urlRe.hasMatch(text)) {
      return Text(text, style: baseStyle);
    }
    final children = <InlineSpan>[];
    var start = 0;
    for (final m in urlRe.allMatches(text)) {
      if (m.start > start) {
        children.add(TextSpan(text: text.substring(start, m.start), style: baseStyle));
      }
      final url = m.group(0)!;
      children.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () => _openUrl(url),
            child: Text(
              url,
              style: baseStyle?.copyWith(color: primary, decoration: TextDecoration.underline),
            ),
          ),
        ),
      );
      start = m.end;
    }
    if (start < text.length) {
      children.add(TextSpan(text: text.substring(start), style: baseStyle));
    }
    return Text.rich(TextSpan(children: children));
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showReportDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.report),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(labelText: context.l10n.reason),
          maxLines: 2,
        ),
        actions: [
          AppButton(
            label: context.l10n.cancel,
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.pop(ctx),
          ),
          AppButton(
            label: context.l10n.submit,
            variant: AppButtonVariant.primary,
            onPressed: () async {
              final uid = ref.read(currentUserAsyncProvider).valueOrNull?.uid;
              if (uid == null) return;
              await ref.read(reportRepositoryProvider).createReport(
                    postId: widget.postId,
                    reporterId: uid,
                    reason: reasonController.text.trim(),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}

class _PostDetailLoadingBody extends StatelessWidget {
  const _PostDetailLoadingBody();

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonCircle(size: 40),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLine(width: 140, height: 14, radius: AppRadii.xs),
                      const SizedBox(height: AppSpacing.sm),
                      SkeletonLine(width: 88, height: 10, radius: AppRadii.xs),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SkeletonLine(width: double.infinity, height: 22, radius: AppRadii.xs),
            const SizedBox(height: AppSpacing.sm),
            SkeletonLine(width: MediaQuery.sizeOf(context).width * 0.55, height: 22, radius: AppRadii.xs),
            const SizedBox(height: AppSpacing.lg),
            SkeletonLine(width: double.infinity, height: _PostDetailPageState._heroImageHeight, radius: AppRadii.md),
            const SizedBox(height: AppSpacing.lg),
            SkeletonLine(width: double.infinity, height: 12),
            const SizedBox(height: AppSpacing.sm),
            SkeletonLine(width: double.infinity, height: 12),
            const SizedBox(height: AppSpacing.sm),
            SkeletonLine(width: 200, height: 12),
          ],
        ),
      ),
    );
  }
}

final reportRepositoryProvider = Provider<ReportRepository>((ref) => ReportRepository());
