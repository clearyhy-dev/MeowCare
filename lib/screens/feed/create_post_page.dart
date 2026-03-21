import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/topic_l10n.dart';
import '../../providers/breed_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/user_provider.dart';

class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key});

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _contentController = TextEditingController();
  List<String> _topics = [];
  List<String> _breedIds = [];
  final String _coverUrl = '';
  bool _loading = false;
  static const _topicOptions = ['care', 'health', 'feeding', 'behavior'];

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _onAiRewrite() async {
    final locale = Localizations.localeOf(context).languageCode;
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
          'summary': '',
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
      final summary = data?['summary'] as String?;
      if (content != null) _contentController.text = content;
      if (summary != null) _summaryController.text = summary;
      if (content != null || summary != null) {
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
      await ref.read(postRepositoryProvider).createPost(
            authorId: user.uid,
            title: title,
            summary: _summaryController.text.trim(),
            content: _contentController.text.trim(),
            coverUrl: _coverUrl,
            breedIds: _breedIds,
            topics: _topics,
            status: 'published',
            countryCode: countryCode,
          );

      if (mounted) {
        context.go(AppRouter.home);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final breedsAsync = ref.watch(breedsFutureProvider);
    final locale = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.createPost),
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(context.l10n.postButton),

          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: context.l10n.title, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _summaryController,
              decoration: InputDecoration(labelText: context.l10n.summary, border: const OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(labelText: context.l10n.content, border: const OutlineInputBorder()),
              maxLines: 6,
            ),
            const SizedBox(height: 16),
            Text(context.l10n.breeds, style: Theme.of(context).textTheme.titleSmall),
            breedsAsync.when(
              data: (breeds) => Wrap(
                spacing: 8,
                children: breeds.map((b) => FilterChip(
                  label: Text(b.displayName(locale)),
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
                )).toList(),
              ),
              loading: () => const SizedBox(height: 32, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.failedToLoadBreeds, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => ref.invalidate(breedsFutureProvider),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(context.l10n.retry),
                  ),
                ],
              ),

            ),
            const SizedBox(height: 16),
            Text(context.l10n.topics, style: Theme.of(context).textTheme.titleSmall),
            Wrap(
              spacing: 8,
              children: _topicOptions.map((t) => FilterChip(
                label: Text(topicLabel(context, t)),
                selected: _topics.contains(t),

                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _topics = [..._topics, t];
                    } else {
                      _topics = _topics.where((x) => x != t).toList();
                    }
                  });
                },
              )).toList(),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: Text(context.l10n.aiRewriteLabel),
              onPressed: _loading ? null : _onAiRewrite,
            ),


          ],
        ),
      ),
    );
  }
}

