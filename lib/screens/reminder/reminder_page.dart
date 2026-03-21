import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/l10n_ext.dart';
import '../../data/repositories/reminder_repository.dart';
import 'package:meowcare/models/cat_model.dart';
import '../../models/reminder_model.dart';
import '../../providers/user_provider.dart';
import '../../screens/cats/my_cats_page.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) => ReminderRepository());

class ReminderPage extends ConsumerStatefulWidget {
  const ReminderPage({super.key});

  @override
  ConsumerState<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends ConsumerState<ReminderPage> {
  final _dewormDaysController = TextEditingController();
  final _bathDaysController = TextEditingController();
  DateTime? _vaccineDate;
  String? _selectedCatId;

  @override
  void dispose() {
    _dewormDaysController.dispose();
    _bathDaysController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedCatId == null) return;
    final deworm = int.tryParse(_dewormDaysController.text);
    final bath = int.tryParse(_bathDaysController.text);
    final now = DateTime.now();
    DateTime? next = _vaccineDate;
    if (deworm != null && deworm > 0) {
      final d = now.add(Duration(days: deworm));
      if (next == null || d.isBefore(next)) next = d;
    }
    if (bath != null && bath > 0) {
      final d = now.add(Duration(days: bath));
      if (next == null || d.isBefore(next)) next = d;
    }
    await ref.read(reminderRepositoryProvider).setReminder(ReminderModel(
          catId: _selectedCatId!,
          dewormingCycleDays: deworm,
          bathCycleDays: bath,
          vaccineNextDate: _vaccineDate,
          nextReminderDate: next ?? now,
          updatedAt: now,
        ));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserAsyncProvider).valueOrNull;
    final catsAsync = ref.watch(myCatsListProvider);
    final List<CatModel> cats = catsAsync.valueOrNull ?? [];

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.reminders)),
        body: Center(child: Text(context.l10n.signInToSetReminders)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.reminders)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButton<String>(
              value: _selectedCatId,
              hint: Text(context.l10n.selectCat),
              items: [
                DropdownMenuItem(value: null, child: Text(context.l10n.noneOption)),
                ...cats.map((c) => DropdownMenuItem(value: c.catId, child: Text(c.name))),

              ],
              onChanged: (v) => setState(() => _selectedCatId = v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dewormDaysController,
              decoration: InputDecoration(labelText: context.l10n.dewormCycleDays, border: const OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bathDaysController,
              decoration: InputDecoration(labelText: context.l10n.bathCycleDays, border: const OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(_vaccineDate != null ? '${context.l10n.vaccine}: ${_vaccineDate!.toString().substring(0, 10)}' : context.l10n.vaccineNextDate),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (d != null) setState(() => _vaccineDate = d);
              },
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(context.l10n.saveReminder)),

          ],
        ),
      ),
    );
  }
}

final myCatsListProvider = FutureProvider<List<CatModel>>((ref) async {
  final uid = ref.watch(currentUserAsyncProvider).valueOrNull?.uid;
  if (uid == null) return [];
  final r = await ref.read(myCatsRepositoryProvider).getMyCats(uid: uid, limit: 50);
  return r.list;
});


