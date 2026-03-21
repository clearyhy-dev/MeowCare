import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/app_language_display.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/topic_l10n.dart';
import '../../data/repositories/report_repository.dart';
import '../../models/post_model.dart';
import '../../providers/feed_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/comment_list.dart';
import '../../widgets/post/post_action_bar.dart';
import '../../widgets/app/app_section_header.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final onVar = scheme.onSurfaceVariant;
    final hasCategory = post.topics.isNotEmpty;

    return Scaffold(
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
        ),
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
                  const SizedBox(height: 12),
                  Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  _linkedPostContent(context, post.content),
                  const SizedBox(height: 12),
                  AppSectionHeader(title: '${context.l10n.comments} (${post.commentCount})'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
                    ),
                    child: CommentList(
                      postId: widget.postId,
                      currentUid: user?.uid,
                      onCommentAdded: _load,
                      currentUserDisplayName: ((user?.displayName ?? '').isNotEmpty) ? user?.displayName : user?.email,
                      currentUserPhotoUrl: ((user?.photoUrl ?? '').isNotEmpty) ? user?.photoUrl : null,
                    ),
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
