import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/app_language_display.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/meow_share.dart';
import '../../core/utils/topic_l10n.dart';
import '../../data/repositories/report_repository.dart';
import '../../models/post_model.dart';
import '../../providers/feed_provider.dart';
import '../../providers/like_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/comment_list.dart';

class PostDetailPage extends ConsumerStatefulWidget {
  const PostDetailPage({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  static const _kErrorPostNotFound = 'post_not_found';
  static const double _heroImageHeight = 160;
  static const double _imageRadius = 11;

  PostModel? _post;
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    final repo = ref.read(postRepositoryProvider);
    final post = await repo.getPost(widget.postId);
    if (mounted) {
      setState(() {
        _post = post;
        _loading = false;
        if (post == null) _error = 'post_not_found';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  static String _formatTime(DateTime? t) {
    if (t == null) return '';
    return DateFormat.yMMMd().add_jm().format(t.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.post)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _post == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.post)),
        body: Center(
          child: Text(_error == _kErrorPostNotFound ? context.l10n.postNotFound : (_error ?? context.l10n.notFound)),
        ),
      );
    }
    final post = _post!;
    final user = ref.watch(currentUserAsyncProvider).valueOrNull;
    final myVote = ref.watch(myEffectiveVoteProvider(widget.postId));
    final voteUi = ref.watch(voteUiStateProvider(widget.postId));
    final displayedUp = post.likeCount + (voteUi?.upDelta ?? 0);
    final displayedDown = post.downvoteCount + (voteUi?.downDelta ?? 0);
    final scheme = Theme.of(context).colorScheme;
    final onVar = scheme.onSurfaceVariant;
    final hasCategory = post.topics.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.post),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: context.l10n.share,
            onPressed: () => MeowShare.sharePost(
                  context,
                  postId: widget.postId,
                  title: post.title,
                ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_upward, color: myVote == 1 ? scheme.primary : null),
            onPressed: () async {
              if (user == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.signInForFullFeatures)));
                }
                return;
              }
              await toggleUpvote(ref, widget.postId);
              _load();
              clearVoteUiState(ref, widget.postId);
            },
          ),
          IconButton(
            icon: Icon(Icons.arrow_downward, color: myVote == -1 ? scheme.error : null),
            onPressed: () async {
              if (user == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.signInForFullFeatures)));
                }
                return;
              }
              await toggleDownvote(ref, widget.postId);
              _load();
              clearVoteUiState(ref, widget.postId);
            },
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            onPressed: user == null ? null : () => _showReportDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _DetailChip(text: AppLanguageDisplay.chipLabel(post.language, context.l10n)),
                      if (hasCategory)
                        _DetailChip(text: feedTopicCategoryLabel(context, post.topics.first)),
                      if (_formatTime(post.createdAt).isNotEmpty)
                        Text(
                          _formatTime(post.createdAt),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: onVar),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    post.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                  ),
                  if (post.shouldShowImage) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(_imageRadius),
                      child: SizedBox(
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
                                  value: total != null && total > 0 ? progress.cumulativeBytesLoaded / total : null,
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
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                        icon: Icon(
                          Icons.arrow_upward,
                          size: 18,
                          color: myVote == 1 ? scheme.primary : onVar,
                        ),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final l10n = context.l10n;
                          if (user == null) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(l10n.signInForFullFeatures)),
                            );
                            return;
                          }
                          try {
                            await toggleUpvote(ref, widget.postId);
                            _load();
                            clearVoteUiState(ref, widget.postId);
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      Text('${displayedUp < 0 ? 0 : displayedUp}', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: onVar)),
                      const SizedBox(width: 12),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                        icon: Icon(Icons.arrow_downward, size: 18, color: myVote == -1 ? scheme.error : onVar),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final l10n = context.l10n;
                          if (user == null) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(l10n.signInForFullFeatures)),
                            );
                            return;
                          }
                          try {
                            await toggleDownvote(ref, widget.postId);
                            _load();
                            clearVoteUiState(ref, widget.postId);
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      Text('${displayedDown < 0 ? 0 : displayedDown}', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: onVar)),
                      const SizedBox(width: 18),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                        icon: Icon(Icons.chat_bubble_outline, size: 17, color: onVar),
                        onPressed: () => _openCommentsSheet(
                          context,
                          uid: user?.uid,
                          displayName: user?.displayName,
                          email: user?.email,
                          photoUrl: user?.photoUrl,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('${post.commentCount}', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: onVar)),
                      const SizedBox(width: 18),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                        icon: Icon(Icons.repeat, size: 18, color: onVar),
                        onPressed: () => MeowShare.sharePost(context, postId: widget.postId, title: post.title),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  _linkedPostContent(context, post.content),
                  const SizedBox(height: 8),
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

  Future<void> _openCommentsSheet(
    BuildContext context, {
    required String? uid,
    required String? displayName,
    required String? email,
    required String? photoUrl,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
            ),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.comments,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: CommentList(
                      postId: widget.postId,
                      currentUid: uid,
                      onCommentAdded: _load,
                      currentUserDisplayName: (displayName != null && displayName.isNotEmpty) ? displayName : email,
                      currentUserPhotoUrl: (photoUrl != null && photoUrl.isNotEmpty) ? photoUrl : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.cancel)),
          FilledButton(
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
            child: Text(context.l10n.submit),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

final reportRepositoryProvider = Provider<ReportRepository>((ref) => ReportRepository());
