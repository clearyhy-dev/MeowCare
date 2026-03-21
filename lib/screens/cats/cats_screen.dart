import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/upload/storage_repository.dart';
import '../../widgets/network_avatar.dart';
import '../../models/cat_model.dart';
import '../../providers/cat_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app/app_empty_state.dart';
import '../../widgets/upgrade_dialog.dart';

final _storageRepositoryProvider = Provider<StorageRepository>((ref) => StorageRepository());

String _catActivityLabel(BuildContext context, ActivityLevel level) {
  switch (level) {
    case ActivityLevel.low:
      return context.l10n.activityLow;
    case ActivityLevel.medium:
      return context.l10n.activityMedium;
    case ActivityLevel.high:
      return context.l10n.activityHigh;
  }
}

class CatsScreen extends ConsumerWidget {
  const CatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserAsyncProvider).valueOrNull;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.cats)),
        body: AppEmptyState(
          message: context.l10n.signInForFullFeatures,
          icon: Icons.pets_outlined,
          action: OutlinedButton.icon(
            icon: const Icon(Icons.account_circle_outlined),
            label: Text(context.l10n.signInWithGoogle),
            onPressed: () => context.push(AppRouter.auth),
          ),
        ),
      );
    }
    final catsAsync = ref.watch(currentFamilyCatsFutureProvider);
    final userAsync = ref.watch(currentUserAsyncProvider);
    final statusAsync = ref.watch(subscriptionStatusProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.cats)),
      body: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.errorWithMessage(e.toString()))),
        data: (cats) {
          if (cats.isEmpty) {
            return AppEmptyState(
              message: context.l10n.noCatsYet,
              icon: Icons.pets,
              action: FilledButton.icon(
                icon: const Icon(Icons.add),
                label: Text(context.l10n.addFirstCat),
                onPressed: () => _goToAddCat(context, ref, userAsync.valueOrNull, statusAsync.valueOrNull),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cats.length,
            itemBuilder: (context, i) {
              final cat = cats[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: NetworkAvatar(imageUrl: cat.avatarUrl),
                  title: Text(cat.name),
                  subtitle: Text('${cat.weight} kg · ${_catActivityLabel(context, cat.activityLevel)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openCatForm(context, ref, cat),
                ),
              );

            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToAddCat(context, ref, userAsync.valueOrNull, statusAsync.valueOrNull),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _goToAddCat(BuildContext context, WidgetRef ref, dynamic user, dynamic status) {
    final familyId = user?.familyId;
    if (familyId == null) return;
    final isPro = status == SubscriptionStatus.pro;
    ref.read(catServiceProvider).canAddCat(familyId, isPro).then((can) {
      if (!context.mounted) return;
      if (!can) {
        showUpgradeDialog(context, onSeePro: () => context.push('${AppRouter.home}subscription'));
        return;
      }

      _openCatForm(context, ref, null);
    });
  }

  void _openCatForm(BuildContext context, WidgetRef ref, CatModel? cat) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _CatFormScreen(cat: cat, onSaved: () => ref.invalidate(currentFamilyCatsFutureProvider)),
      ),
    );
  }
}

class _CatFormScreen extends ConsumerStatefulWidget {
  const _CatFormScreen({this.cat, required this.onSaved});

  final CatModel? cat;
  final VoidCallback onSaved;

  @override
  ConsumerState<_CatFormScreen> createState() => _CatFormScreenState();
}

class _CatFormScreenState extends ConsumerState<_CatFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _breedController;
  late TextEditingController _weightController;
  DateTime? _birthday;
  bool _neutered = false;
  ActivityLevel _activityLevel = ActivityLevel.medium;
  bool _loading = false;
  String _avatarUrl = '';
  late String _pendingCatId;

  @override
  void initState() {
    super.initState();
    _pendingCatId = widget.cat?.catId ?? const Uuid().v4();
    _nameController = TextEditingController(text: widget.cat?.name ?? '');
    _breedController = TextEditingController(text: widget.cat?.breedId ?? '');
    final w = widget.cat?.weight ?? 0.0;
    _weightController = TextEditingController(text: w > 0 ? w.toString() : '');
    _birthday = widget.cat?.birthday;
    _neutered = widget.cat?.neutered ?? false;
    _activityLevel = widget.cat?.activityLevel ?? ActivityLevel.medium;
    _avatarUrl = widget.cat?.avatarUrl ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x == null || !mounted) return;
    final user = ref.read(currentUserAsyncProvider).valueOrNull;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final url = await ref.read(_storageRepositoryProvider).uploadCatAvatar(user.uid, _pendingCatId, File(x.path));
      if (mounted) setState(() => _avatarUrl = url);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserAsyncProvider).valueOrNull;
    final familyId = user?.familyId;
    if (familyId == null) return;
    setState(() => _loading = true);
    final catId = widget.cat?.catId ?? _pendingCatId;
    final cat = CatModel(
      catId: catId,
      ownerId: user?.uid ?? '',
      familyId: familyId,
      name: _nameController.text.trim(),
      breedId: _breedController.text.trim(),
      avatarUrl: _avatarUrl,
      isPublic: widget.cat?.isPublic ?? false,
      ownerNotes: widget.cat?.ownerNotes ?? '',
      birthday: _birthday,
      weight: double.tryParse(_weightController.text.trim()) ?? 0,
      neutered: _neutered,
      activityLevel: _activityLevel,
      createdAt: widget.cat?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (widget.cat == null) {
        await ref.read(catServiceProvider).createCat(cat);
      } else {
        await ref.read(catServiceProvider).updateCat(cat);
      }
      if (mounted) {
        widget.onSaved();
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cat == null ? context.l10n.addCat : context.l10n.editCat),
        actions: [
          if (widget.cat != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final nav = Navigator.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(context.l10n.deleteCat),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.cancel)),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.l10n.delete, style: TextStyle(color: Theme.of(ctx).colorScheme.error))),

                    ],
                  ),
                );
                if (confirm != true) return;
                if (!context.mounted) return;
                await ref.read(catServiceProvider).deleteCat(widget.cat!.catId);
                if (!context.mounted) return;
                widget.onSaved();
                nav.pop();
              },
            ),

        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _loading ? null : _pickImage,
                child: _avatarUrl.isEmpty
                    ? CircleAvatar(
                        radius: 48,
                        child: Icon(Icons.add_a_photo, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      )
                    : NetworkAvatar(imageUrl: _avatarUrl, radius: 48, placeholder: Icon(Icons.add_a_photo, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(

              controller: _nameController,
              decoration: InputDecoration(labelText: context.l10n.name, border: const OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? context.l10n.enterName : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_birthday != null ? '${context.l10n.birthday}: ${_birthday!.toIso8601String().split('T').first}' : context.l10n.birthday),
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: _birthday ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now());
                if (d != null) setState(() => _birthday = d);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _weightController,
              decoration: InputDecoration(labelText: context.l10n.weight, border: const OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            SwitchListTile(title: Text(context.l10n.neutered), value: _neutered, onChanged: (v) => setState(() => _neutered = v)),
            DropdownButtonFormField<ActivityLevel>(
              key: ValueKey(_activityLevel),
              initialValue: _activityLevel,
              decoration: InputDecoration(labelText: context.l10n.activity, border: const OutlineInputBorder()),
              items: ActivityLevel.values.map((e) => DropdownMenuItem(value: e, child: Text(_catActivityLabel(context, e)))).toList(),
              onChanged: (v) => setState(() => _activityLevel = v ?? ActivityLevel.medium),
            ),

            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(context.l10n.save),

            ),
          ],
        ),
      ),
    );
  }
}

