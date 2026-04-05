import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../core/constants/post_communities.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_feedback.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/topic_l10n.dart';
import '../../models/post_media_item.dart';
import '../../providers/feed_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app/minimal_multiline_field.dart';

/// Reddit 风格发帖：必选社区、标题、可选标签/flair、正文、底部工具栏（链接 / 图 / 视频）。
class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key});

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

sealed class _MediaSlot {}

class _SlotImage extends _MediaSlot {
  _SlotImage(this.file);
  final File file;
}

class _SlotVideo extends _MediaSlot {
  _SlotVideo(this.file, this.duration);
  final File file;
  final Duration duration;
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<_MediaSlot> _slots = [];
  bool _loading = false;

  String? _communityKey;
  final Set<String> _extraTopicKeys = {};
  String _linkUrl = '';

  static const double _previewHeight = 120;
  static const double _previewRadius = 10;
  static const int _maxImages = 6;
  static const int _maxVideoSeconds = 40;

  int get _imageCount => _slots.whereType<_SlotImage>().length;
  bool get _hasVideo => _slots.whereType<_SlotVideo>().isNotEmpty;

  bool get _canPost =>
      _titleController.text.trim().isNotEmpty && _communityKey != null && _communityKey!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  List<String> get _topicsForFirestore {
    final out = <String>[];
    if (_communityKey != null) out.add(_communityKey!);
    for (final k in _extraTopicKeys) {
      if (k != _communityKey && !out.contains(k)) out.add(k);
    }
    return out;
  }

  Future<void> _pickImages() async {
    final remain = _maxImages - _imageCount;
    if (remain <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.postMaxSixImages)));
      }
      return;
    }
    try {
      final files = await ImagePicker().pickMultiImage(
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 88,
      );
      if (files.isEmpty) return;
      setState(() {
        for (final x in files) {
          if (_imageCount >= _maxImages) break;
          _slots.add(_SlotImage(File(x.path)));
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.postImagePickFailed)));
      }
    }
  }

  Future<void> _pickVideo() async {
    if (_hasVideo) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.postOneVideoOnly)));
      }
      return;
    }
    try {
      final x = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: _maxVideoSeconds),
      );
      if (x == null) return;
      final file = File(x.path);
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      final d = controller.value.duration;
      await controller.dispose();
      if (d > const Duration(seconds: _maxVideoSeconds)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.postVideoTooLong)));
        }
        return;
      }
      setState(() => _slots.add(_SlotVideo(file, d)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.postVideoPickFailed)));
      }
    }
  }

  void _removeAt(int index) {
    setState(() => _slots.removeAt(index));
  }

  Future<void> _showCommunityPicker() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                context.l10n.postSelectCommunity,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            for (final key in kPostCommunityKeys)
              ListTile(
                title: Text(feedTopicCategoryLabel(context, key)),
                trailing: _communityKey == key ? Icon(Icons.check_rounded, color: Theme.of(ctx).colorScheme.primary) : null,
                onTap: () => Navigator.pop(ctx, key),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        _communityKey = picked;
        _extraTopicKeys.remove(picked);
      });
    }
  }

  Future<void> _showFlairSheet() async {
    if (_communityKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.postNeedCommunity)));
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: 16 + MediaQuery.paddingOf(ctx).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.l10n.postAddTagsFlairOptional,
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final key in kPostCommunityKeys)
                            if (key != _communityKey)
                              FilterChip(
                                label: Text(feedTopicCategoryLabel(context, key)),
                                selected: _extraTopicKeys.contains(key),
                                onSelected: (sel) {
                                  setState(() {
                                    if (sel) {
                                      _extraTopicKeys.add(key);
                                    } else {
                                      _extraTopicKeys.remove(key);
                                    }
                                  });
                                  setModal(() {});
                                },
                              ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(context.l10n.ok),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showLinkDialog() async {
    final c = TextEditingController(text: _linkUrl);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.postLinkAttachment),
        content: TextField(
          controller: c,
          decoration: InputDecoration(hintText: 'https://'),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.l10n.ok)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final raw = c.text.trim();
    if (raw.isEmpty) {
      setState(() => _linkUrl = '');
      return;
    }
    final uri = Uri.tryParse(raw);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.postInvalidUrl)));
      return;
    }
    setState(() => _linkUrl = raw);
  }

  void _stub(String kind) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${context.l10n.postFeatureComingSoon} ($kind)')),
    );
  }

  Future<void> _submit() async {
    if (!_canPost) {
      if (_communityKey == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.postNeedCommunity)));
      }
      return;
    }
    final title = _titleController.text.trim();
    final user = ref.read(currentUserAsyncProvider).valueOrNull;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final countryCode = ref.read(appCountryProvider).valueOrNull ?? '';
      final lang = ref.read(effectiveUILanguageCodeProvider);
      final post = await ref.read(postRepositoryProvider).createPost(
            authorId: user.uid,
            title: title,
            content: _contentController.text.trim(),
            coverUrl: '',
            breedIds: const [],
            topics: _topicsForFirestore,
            status: 'published',
            countryCode: countryCode,
            language: lang,
            hasImage: _slots.isNotEmpty ? true : null,
            linkUrl: _linkUrl.trim(),
          );

      if (_slots.isNotEmpty) {
        final storage = ref.read(storageRepositoryProvider);
        final repo = ref.read(postRepositoryProvider);
        final uploaded = <PostMediaItem>[];
        var imgIdx = 0;
        for (final slot in _slots) {
          if (slot is _SlotImage) {
            final url = await storage.uploadPostGalleryImage(post.postId, imgIdx++, slot.file);
            uploaded.add(PostMediaItem.image(url));
          } else if (slot is _SlotVideo) {
            final data = await VideoThumbnail.thumbnailData(
              video: slot.file.path,
              imageFormat: ImageFormat.JPEG,
              maxWidth: 1280,
              quality: 85,
            );
            if (data == null) {
              throw StateError('thumb');
            }
            final tmp = File('${Directory.systemTemp.path}/meow_vthumb_${post.postId}.jpg');
            await tmp.writeAsBytes(data);
            try {
              final thumbUrl = await storage.uploadPostVideoThumbnail(post.postId, tmp);
              final videoUrl = await storage.uploadPostVideo(post.postId, slot.file);
              uploaded.add(PostMediaItem.video(videoUrl, thumbUrl));
            } finally {
              if (tmp.existsSync()) tmp.deleteSync();
            }
          }
        }
        await repo.updatePostMedia(postId: post.postId, mediaItems: uploaded);
      }

      ref.invalidate(feedProvider);
      if (mounted) {
        await AppFeedback.success();
        if (!mounted) return;
        context.go(AppRouter.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithMessage(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _loading ? null : () => context.pop(),
          tooltip: MaterialLocalizations.of(context).cancelButtonLabel,
        ),
        title: const SizedBox.shrink(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: (_loading || !_canPost) ? null : _submit,
              child: _loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
                    )
                  : Text(
                      context.l10n.postButton,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _canPost ? scheme.primary : scheme.onSurface.withValues(alpha: 0.38),
                      ),
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Material(
        elevation: 8,
        color: scheme.surface,
        child: SafeArea(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: scheme.outline.withValues(alpha: 0.12))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  tooltip: context.l10n.postLinkAttachment,
                  icon: Icon(Icons.link_rounded, color: scheme.onSurfaceVariant),
                  onPressed: _loading ? null : _showLinkDialog,
                ),
                IconButton(
                  tooltip: context.l10n.postAddImages,
                  icon: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant),
                  onPressed: _loading ? null : _pickImages,
                ),
                IconButton(
                  tooltip: context.l10n.postAddVideo,
                  icon: Icon(Icons.videocam_outlined, color: scheme.onSurfaceVariant),
                  onPressed: _loading ? null : _pickVideo,
                ),
                IconButton(
                  tooltip: 'Poll',
                  icon: Icon(Icons.poll_outlined, color: scheme.onSurfaceVariant.withValues(alpha: 0.45)),
                  onPressed: _loading ? null : () => _stub('poll'),
                ),
                IconButton(
                  tooltip: 'AMA',
                  icon: Icon(Icons.record_voice_over_outlined, color: scheme.onSurfaceVariant.withValues(alpha: 0.45)),
                  onPressed: _loading ? null : () => _stub('ama'),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _loading ? null : _showCommunityPicker,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _communityKey == null
                              ? context.l10n.postSelectCommunity
                              : feedTopicCategoryLabel(context, _communityKey!),
                          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(Icons.unfold_more_rounded, color: scheme.onSurfaceVariant, size: 22),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.2),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: context.l10n.title,
                hintStyle: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface.withValues(alpha: 0.35),
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 5,
            ),
            if (_linkUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  label: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: Text(_linkUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  avatar: Icon(Icons.link_rounded, size: 18, color: scheme.primary),
                  onDeleted: _loading ? null : () => setState(() => _linkUrl = ''),
                ),
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: (_loading || _communityKey == null) ? null : _showFlairSheet,
              icon: Icon(Icons.sell_outlined, size: 18, color: scheme.onSurfaceVariant),
              label: Text(
                context.l10n.postAddTagsFlairOptional,
                style: textTheme.labelLarge,
              ),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                side: BorderSide(color: scheme.outline.withValues(alpha: 0.35)),
              ),
            ),
            if (_extraTopicKeys.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _extraTopicKeys
                    .map(
                      (k) => Chip(
                        label: Text(feedTopicCategoryLabel(context, k)),
                        onDeleted: _loading
                            ? null
                            : () => setState(() => _extraTopicKeys.remove(k)),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            if (_slots.isNotEmpty) ...[
              ...List.generate(_slots.length, (i) {
                final s = _slots[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(_previewRadius),
                        child: SizedBox(
                          height: _previewHeight,
                          width: double.infinity,
                          child: s is _SlotImage
                              ? Image.file(s.file, fit: BoxFit.cover)
                              : ColoredBox(
                                  color: scheme.surfaceContainerHighest,
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.play_circle_outline_rounded, size: 44, color: scheme.primary),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${(s as _SlotVideo).duration.inSeconds}s',
                                          style: textTheme.labelMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      Material(
                        color: scheme.onSurface.withValues(alpha: 0.62),
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: _loading ? null : () => _removeAt(i),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
            MinimalMultilineField(
              controller: _contentController,
              hintText: context.l10n.postBodyOptionalHint,
              minLines: 5,
              maxLines: 14,
              showBottomDivider: false,
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
