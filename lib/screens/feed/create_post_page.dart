import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_feedback.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/topic_l10n.dart';
import '../../providers/breed_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app/app_section_header.dart';

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
  List<String> _breedIds = [];
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

  Future<void> _onAiRewrite() async {
    final locale = ref.read(effectiveUILanguageCodeProvider);
    final baseUrl = AppConstants.backendBaseUrl;
    if (baseUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.backendUrlNotConfigured)),
        );
      }
      return;
    }
    final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.pleaseSignIn)));
      }
      return;
    }
    setState(() => _loading = true);
    try {
      final uri = Uri.parse('$baseUrl/ai/rewrite');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'content': _contentController.text,
          'locale': locale,
        }),
      );
      if (!mounted) return;
      if (res.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.aiUnavailableReason('HTTP ${res.statusCode}'))),
        );
        return;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      final content = data?['content'] as String?;
      if (content != null) _contentController.text = content;
      if (content != null) {
        await AppFeedback.success();
        if (!mounted) return;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.contentUpdated)),
        );
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
            breedIds: _breedIds,
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
    final breedsAsync = ref.watch(breedsFutureProvider);
    final locale = ref.watch(effectiveUILanguageCodeProvider);
    final scheme = Theme.of(context).colorScheme;
    final divider = Theme.of(context).dividerColor.withValues(alpha: 0.35);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.createPost),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: divider),
                boxShadow: AppShadows.subtle,
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSectionHeader(title: context.l10n.title),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: context.l10n.title,
                      hintStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 4,
                    minLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppSectionHeader(title: context.l10n.content),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      hintText: context.l10n.content,
                      alignLabelWithHint: true,
                    ),
                    maxLines: 10,
                    minLines: 5,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.image_outlined, size: 20),
                    label: Text(context.l10n.postAddImage),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
                    ),
                    onPressed: _loading ? null : _pickCoverImage,
                  ),
                ],
              ),
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
                    color: scheme.onSurface.withValues(alpha: 0.62),
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
            Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: divider),
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSectionHeader(title: context.l10n.breeds),
                  const SizedBox(height: 8),
                  breedsAsync.when(
                    data: (breeds) => Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: breeds
                          .map(
                            (b) => FilterChip(
                              label: Text(b.displayName(locale), style: const TextStyle(fontSize: 13)),
                              selected: _breedIds.contains(b.breedId),
                              onSelected: (v) {
                                setState(() {
                                  if (v) {
                                    _breedIds = [..._breedIds, b.breedId];
                                  } else {
                                    _breedIds = _breedIds.where((id) => id != b.breedId).toList();
                                  }
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    loading: () => const SizedBox(height: 36, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                    error: (_, __) => Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.failedToLoadBreeds, style: TextStyle(color: scheme.error)),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => ref.invalidate(breedsFutureProvider),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: Text(context.l10n.retry),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppSectionHeader(title: context.l10n.topics),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _topicsInputController,
                    onChanged: (v) => setState(() => _syncTopicsFromInput(v)),
                    decoration: InputDecoration(
                      hintText: '#care #feeding your description...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.auto_awesome, size: 20),
              label: Text(context.l10n.aiRewriteLabel),
              onPressed: _loading ? null : _onAiRewrite,
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(context.l10n.postButton),
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
