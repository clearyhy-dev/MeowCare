import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/l10n_ext.dart';
import '../../models/cat_model.dart';
import '../../models/health_model.dart';
import '../../providers/cat_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/health_service.dart';
import '../../widgets/app/app_empty_state.dart';
import '../../widgets/cat_selector.dart';

String _healthLogTypeLabel(BuildContext context, HealthLogType type) {
  final l10n = context.l10n;
  switch (type) {
    case HealthLogType.weight: return l10n.healthWeight;
    case HealthLogType.deworm: return l10n.healthDeworm;
    case HealthLogType.vaccine: return l10n.healthVaccine;
    case HealthLogType.note: return l10n.healthNote;
  }
}

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserAsyncProvider).valueOrNull;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.health)),
        body: AppEmptyState(
          message: context.l10n.signInForFullFeatures,
          icon: Icons.health_and_safety_outlined,
          action: OutlinedButton.icon(
            icon: const Icon(Icons.account_circle_outlined),
            label: Text(context.l10n.signInWithGoogle),
            onPressed: () => context.push(AppRouter.auth),
          ),
        ),
      );
    }
    final catsAsync = ref.watch(currentFamilyCatsFutureProvider);
    final cats = catsAsync.valueOrNull ?? [];
    if (cats.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.health)),
        body: AppEmptyState(message: context.l10n.addCatFirstHealth, icon: Icons.pets_outlined),
      );
    }
    return DefaultTabController(

      length: cats.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.health),
          bottom: TabBar(
            tabs: cats.map((c) => Tab(text: c.name)).toList(),
          ),
        ),
        body: TabBarView(
          children: cats.map((c) => _HealthLogList(catId: c.catId, catName: c.name)).toList(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openAddLog(context, ref, cats),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _openAddLog(BuildContext context, WidgetRef ref, List<dynamic> cats) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _AddHealthLogScreen(cats: cats, onSaved: () => ref.invalidate(currentFamilyCatsFutureProvider)),
      ),
    );
  }
}

class _HealthLogList extends ConsumerWidget {
  const _HealthLogList({required this.catId, required this.catName});

  final String catId;
  final String catName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(_healthLogsProvider(catId));

    return logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(context.l10n.errorWithMessage(e.toString()), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => ref.invalidate(_healthLogsProvider(catId)),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return Center(child: Text(context.l10n.noHealthLogs(catName)));
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: logs.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            thickness: 0.5,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
          ),
          itemBuilder: (context, i) {
            final log = logs[i];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              title: Text(
                '${_healthLogTypeLabel(context, log.type)}${log.type == HealthLogType.weight ? ': ${log.value}' : ''}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('${AppDateUtils.formatDate(log.createdAt)}${log.note.isNotEmpty ? ' · ${log.note}' : ''}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await ref.read(healthServiceProvider).deleteHealthLog(log.logId);
                  ref.invalidate(_healthLogsProvider(catId));
                },
              ),
            );
          },
        );
      },
    );
  }
}

final healthServiceProvider = Provider<HealthService>((ref) => HealthService());

final _healthLogsProvider = FutureProvider.family<List<HealthLogModel>, String>((ref, catId) async {
  return ref.read(healthServiceProvider).getHealthLogsByCatId(catId);
});

class _AddHealthLogScreen extends ConsumerStatefulWidget {
  const _AddHealthLogScreen({required this.cats, required this.onSaved});

  final List<dynamic> cats;
  final VoidCallback onSaved;

  @override
  ConsumerState<_AddHealthLogScreen> createState() => _AddHealthLogScreenState();
}

class _AddHealthLogScreenState extends ConsumerState<_AddHealthLogScreen> {
  final _formKey = GlobalKey<FormState>();
  CatModel? _selectedCat;
  HealthLogType _type = HealthLogType.weight;
  final _valueController = TextEditingController();
  final _noteController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.cats.isNotEmpty) _selectedCat = widget.cats.first as CatModel;
  }

  @override
  void dispose() {
    _valueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedCat == null) return;
    setState(() => _loading = true);
    final logId = const Uuid().v4();
    final value = double.tryParse(_valueController.text.trim()) ?? 0;
    final log = HealthLogModel(
      logId: logId,
      catId: _selectedCat!.catId,
      type: _type,
      value: value,
      note: _noteController.text.trim(),
      createdAt: DateTime.now(),
    );
    try {
      await ref.read(healthServiceProvider).addHealthLog(log);
      if (mounted) {
        widget.onSaved();
        ref.invalidate(_healthLogsProvider(_selectedCat!.catId));
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catList = widget.cats as List<CatModel>;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.addHealthLog)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CatSelector(
              cats: catList,
              selectedCatId: _selectedCat?.catId,
              onSelected: (c) => setState(() => _selectedCat = c),
              label: context.l10n.cat,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<HealthLogType>(
              key: ValueKey(_type),
              initialValue: _type,
              decoration: InputDecoration(labelText: context.l10n.type, border: const OutlineInputBorder()),
              items: HealthLogType.values.map((e) => DropdownMenuItem(value: e, child: Text(_healthLogTypeLabel(context, e)))).toList(),

              onChanged: (v) => setState(() => _type = v ?? HealthLogType.weight),
            ),
            if (_type == HealthLogType.weight) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _valueController,
                decoration: InputDecoration(labelText: context.l10n.weight, border: const OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(labelText: context.l10n.note, border: const OutlineInputBorder()),
              maxLines: 2,
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

