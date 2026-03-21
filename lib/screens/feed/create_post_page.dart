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
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/topic_l10n.dart';
import '../../providers/breed_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/user_provider.dart';

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
    final divider = Theme.of(context).dividerColor.withValues(alpha: 0.45);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.createPost),
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
                  )
                : Text(
                    context.l10n.postButton,
                    style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary, fontSize: 15),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: context.l10n.title,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: scheme.primary, width: 1.2),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
            Divider(height: 20, thickness: 0.7, color: divider),
            Text(
              context.l10n.content,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                border: InputBorder.none,
                alignLabelWithHint: true,
              ),
              maxLines: 10,
              minLines: 4,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.image_outlined, size: 20),
              label: Text(context.l10n.postAddImage),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _loading ? null : _pickCoverImage,
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
                    color: Colors.black54,
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
            Text(
              context.l10n.breeds,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
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
                        visualDensity: VisualDensity.compact,
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
            Text(
              context.l10n.topics,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
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
            const SizedBox(height: 18),
            OutlinedButton.icon(
              icon: const Icon(Icons.auto_awesome, size: 20),
              label: Text(context.l10n.aiRewriteLabel),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _loading ? null : _onAiRewrite,
            ),
          ],
        ),
      ),
    );
  }
}
