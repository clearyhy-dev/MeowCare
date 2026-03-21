import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/repositories/report_repository.dart';
import '../../models/post_model.dart';
import '../../providers/bookmark_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(title: Text(context.l10n.post)), body: const Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _post == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.post)),
        body: Center(child: Text(_error == _kErrorPostNotFound ? context.l10n.postNotFound : (_error ?? context.l10n.notFound))),


      );
    }
    final post = _post!;
    final user = ref.watch(currentUserAsyncProvider).valueOrNull;
    final isLikedAsync = ref.watch(isLikedProvider(widget.postId));
    final isBookmarkedAsync = ref.watch(isBookmarkedProvider(widget.postId));

    return Scaffold(
      appBar: AppBar(
        title: Text(post.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: context.l10n.share,
            onPressed: () => Share.share(
              '${post.title}\n\n${context.l10n.shareFromMeowCare}',
              subject: post.title,
            ),
          ),
          IconButton(
            icon: Icon(isLikedAsync.valueOrNull == true ? Icons.favorite : Icons.favorite_border),

            onPressed: () async {
              if (user == null) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.signInForFullFeatures)));
                return;
              }
              await toggleLike(ref, widget.postId);
              ref.invalidate(feedProvider);
              _load();
            },
          ),
          IconButton(
            icon: Icon(isBookmarkedAsync.valueOrNull == true ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () async {
              if (user == null) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.signInForFullFeatures)));
                return;
              }
              await toggleBookmark(ref, widget.postId);
              ref.invalidate(isBookmarkedProvider(widget.postId));
            },
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            onPressed: user == null ? null : () => _showReportDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppInsets.screenPadding, vertical: AppInsets.sectionSpacing / 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.coverUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Image.network(
                  post.coverUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) =>
                      progress == null ? child : const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                  errorBuilder: (context, error, stackTrace) => SizedBox(height: 120, child: Center(child: Icon(Icons.broken_image, size: 48, color: Theme.of(context).colorScheme.outline))),
                ),
              ),
            if (post.coverUrl.isNotEmpty) const SizedBox(height: 16),
            Text(post.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.favorite_border, size: 16, color: Theme.of(context).colorScheme.outline),
                const SizedBox(width: 4),
                Text('${post.likeCount}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(width: 16),
                Icon(Icons.chat_bubble_outline, size: 16, color: Theme.of(context).colorScheme.outline),
                const SizedBox(width: 4),
                Text('${post.commentCount}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 20),
            _linkedPostContent(context, post.content),
            const SizedBox(height: 24),

            if (user != null) ...[
              const Divider(),
              Text(context.l10n.comments, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              CommentList(
                postId: widget.postId,
                currentUid: user.uid,
                onCommentAdded: _load,
                currentUserDisplayName: user.displayName.isNotEmpty ? user.displayName : user.email,
                currentUserPhotoUrl: user.photoUrl.isNotEmpty ? user.photoUrl : null,
              ),

            ],
          ],
        ),
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

final reportRepositoryProvider = Provider<ReportRepository>((ref) => ReportRepository());

