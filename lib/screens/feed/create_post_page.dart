import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_feedback.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/topic_l10n.dart';
import '../../providers/feed_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app/app_section_header.dart';
import '../../widgets/app/minimal_multiline_field.dart';
import '../../widgets/app/minimal_text_field.dart';

/// Reddit 风发帖：标题突出、可选配图（Firebase Storage → coverUrl）、正文与标签紧凑。
class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key});

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _topicsInputController = TextEditingController();
  List<String> _topics = [];
  File? _coverFile;
  bool _loading = false;
  static const _topicOptions = ['care', 'health', 'feeding', 'behavior'];
  static const double _previewHeight = 120;
  static const double _previewRadius = 10;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _topicsInputController.dispose();
    super.dispose();
  }

  void _syncTopicsFromInput(String raw) {
    final hashtagMatches = RegExp(r'#([a-zA-Z_]+)').allMatches(raw);
    final next = <String>[];
    for (final m in hashtagMatches) {
      final token = (m.group(1) ?? '').toLowerCase().trim();
      if (_topicOptions.contains(token) && !next.contains(token)) {
        next.add(token);
      }
    }
    _topics = next;
  }

  String _activeTopicQuery(String raw) {
    final m = RegExp(r'#([a-zA-Z_]*)$').firstMatch(raw);
    return (m?.group(1) ?? '').toLowerCase().trim();
  }

  List<String> _topicSuggestions(String raw) {
    final q = _activeTopicQuery(raw);
    if (q.isEmpty) return _topicOptions;
    return _topicOptions.where((t) => t.startsWith(q)).toList();
  }

  void _appendTopicTag(String topic) {
    final text = _topicsInputController.text;
    if (RegExp('#$topic(\\b|\$)', caseSensitive: false).hasMatch(text)) return;
    final spacer = text.trim().isEmpty || text.trimRight().endsWith('#') ? '' : ' ';
    _topicsInputController.text = '${text.trimRight()}$spacer#$topic ';
    _topicsInputController.selection = TextSelection.collapsed(offset: _topicsInputController.text.length);
    setState(() {
      _syncTopicsFromInput(_topicsInputController.text);
    });
  }

  Future<void> _pickCoverImage() async {
    try {
      final xFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 88,
      );
      if (xFile == null) return;
      setState(() => _coverFile = File(xFile.path));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.postImagePickFailed)));
      }
    }
  }

  void _removeCoverImage() {
    setState(() => _coverFile = null);
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
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
            topics: _topics,
            status: 'published',
            countryCode: countryCode,
            language: lang,
          );

      if (_coverFile != null) {
        try {
          final url = await ref.read(storageRepositoryProvider).uploadPostCover(post.postId, _coverFile!);
          await ref.read(postRepositoryProvider).updatePostCover(postId: post.postId, coverUrl: url);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.postImageUploadFailed)),
            );
          }
        }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.createPost),
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.l10n.postButton),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(title: context.l10n.title),
            const SizedBox(height: 8),
            MinimalTextField(
              controller: _titleController,
              hintText: context.l10n.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.2),
              textCapitalization: TextCapitalization.sentences,
              minLines: 2,
              maxLines: 4,
              showBottomDivider: true,
            ),
            const SizedBox(height: AppSpacing.md),
            AppSectionHeader(title: context.l10n.content),
            const SizedBox(height: 8),
            MinimalMultilineField(
              controller: _contentController,
              hintText: context.l10n.content,
              minLines: 6,
              maxLines: 11,
              showBottomDivider: true,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: _loading ? null : _pickCoverImage,
              icon: const Icon(Icons.image_outlined, size: 20),
              label: Text(context.l10n.postAddImage),
              style: TextButton.styleFrom(alignment: Alignment.centerLeft),
            ),
            if (_coverFile != null) ...[
              const SizedBox(height: 10),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(_previewRadius),
                    child: SizedBox(
                      height: _previewHeight,
                      width: double.infinity,
                      child: Image.file(
                        _coverFile!,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                  Material(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      tooltip: context.l10n.postRemoveImage,
                      onPressed: _removeCoverImage,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            AppSectionHeader(title: context.l10n.topics),
            const SizedBox(height: 8),
            MinimalTextField(
              controller: _topicsInputController,
              hintText: '#care #feeding your description...',
              onChanged: (v) => setState(() => _syncTopicsFromInput(v)),
              showBottomDivider: false,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _topicSuggestions(_topicsInputController.text)
                  .map(
                    (t) => ActionChip(
                      label: Text('#$t ${topicLabel(context, t)}'),
                      onPressed: () => setState(() => _appendTopicTag(t)),
                    ),
                  )
                  .toList(),
            ),
            if (_topics.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: _topics
                    .map(
                      (t) => Chip(
                        label: Text('#$t'),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _topics = _topics.where((e) => e != t).toList();
                            _topicsInputController.text = _topics.map((e) => '#$e').join(' ');
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
