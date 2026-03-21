import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/router/app_router.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/upload/storage_repository.dart';
import '../../widgets/network_avatar.dart';

import '../../models/cat_model.dart';
import '../../providers/breed_provider.dart';
import '../../providers/user_provider.dart';
import 'my_cats_page.dart';


final storageRepositoryProvider = Provider<StorageRepository>((ref) => StorageRepository());

class CatEditPage extends ConsumerStatefulWidget {
  const CatEditPage({super.key, required this.catId});

  final String catId;

  @override
  ConsumerState<CatEditPage> createState() => _CatEditPageState();
}

class _CatEditPageState extends ConsumerState<CatEditPage> {
  final _nameController = TextEditingController();
  final _ownerNotesController = TextEditingController();
  String _breedId = '';
  String _avatarUrl = '';
  bool _isPublic = false;
  bool _loading = false;
  CatModel? _existing;

  @override
  void initState() {
    super.initState();
    if (widget.catId != 'new') _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNotesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ref.read(myCatsRepositoryProvider);
    final cat = await repo.getCat(widget.catId);
    if (mounted && cat != null) {
      setState(() {
        _existing = cat;
        _nameController.text = cat.name;
        _breedId = cat.breedId;
        _ownerNotesController.text = cat.ownerNotes;
        _avatarUrl = cat.avatarUrl;
        _isPublic = cat.isPublic;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    final user = ref.read(currentUserAsyncProvider).valueOrNull;
    if (user == null) return;
    final catId = _existing?.catId ?? const Uuid().v4();
    setState(() => _loading = true);
    try {
      final url = await ref.read(storageRepositoryProvider).uploadCatAvatar(user.uid, catId, File(x.path));
      if (mounted) setState(() => _avatarUrl = url);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final user = ref.read(currentUserAsyncProvider).valueOrNull;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(myCatsRepositoryProvider);
      final catId = _existing?.catId ?? const Uuid().v4();
      final cat = CatModel(
        catId: catId,
        ownerId: user.uid,
        name: name,
        breedId: _breedId.trim(),
        avatarUrl: _avatarUrl,
        isPublic: _isPublic,
        ownerNotes: _ownerNotesController.text.trim(),
        createdAt: _existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      if (_existing == null) {
        await repo.createCat(cat);
      } else {
        await repo.updateCat(cat);
      }
      if (mounted) context.go('${AppRouter.home}my-cats');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final breedsAsync = ref.watch(breedsFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? context.l10n.addCatLabel : context.l10n.editCatLabel),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(context.l10n.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: _avatarUrl.isEmpty
                  ? const CircleAvatar(radius: 48, child: Icon(Icons.add_a_photo, size: 40))
                  : NetworkAvatar(imageUrl: _avatarUrl, radius: 48, placeholder: const Icon(Icons.add_a_photo, size: 40)),
            ),

            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: context.l10n.name, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Text(context.l10n.breeds, style: Theme.of(context).textTheme.titleSmall),
            breedsAsync.when(
              data: (breeds) => DropdownButton<String>(
                value: _breedId.isEmpty ? null : _breedId,
                isExpanded: true,
                hint: Text(context.l10n.selectBreed),
                items: [
                  DropdownMenuItem(value: '', child: Text(context.l10n.noneOption)),
                  ...breeds.map((b) => DropdownMenuItem(value: b.breedId, child: Text(b.displayName(Localizations.localeOf(context).languageCode)))),
                ],
                onChanged: (v) => setState(() => _breedId = v ?? ''),
              ),
              loading: () => const SizedBox(height: 40),
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
            SwitchListTile(
              title: Text(context.l10n.publicProfile),
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
            ),
            TextField(
              controller: _ownerNotesController,
              decoration: InputDecoration(labelText: context.l10n.yourNotes, border: const OutlineInputBorder()),

              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}

