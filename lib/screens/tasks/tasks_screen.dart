import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/l10n_ext.dart';
import '../../models/cat_model.dart';
import '../../models/task_model.dart';
import '../../providers/cat_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/cat_selector.dart';
import '../../widgets/reminder_dialog.dart';
import '../../widgets/task_card.dart';


class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(familyTasksProvider);
    final completionAsync = ref.watch(todayCompletionMapProvider);
    final catsAsync = ref.watch(currentFamilyCatsFutureProvider);
    final userAsync = ref.watch(currentUserAsyncProvider);
    final cats = catsAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tasks),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: cats.isEmpty ? null : () => _openAddTask(context, ref, cats),
          ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.errorWithMessage(e.toString()))),
        data: (tasks) {
          final completion = completionAsync.valueOrNull ?? {};
          final catMap = {for (var c in cats) c.catId: c.name};
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(context.l10n.noTasksYet),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(context.l10n.addTask),
                    onPressed: cats.isEmpty ? null : () => _openAddTask(context, ref, cats),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: tasks.length,
            itemBuilder: (context, i) {
              final task = tasks[i];
              return TaskCard(
                task: task,
                catName: catMap[task.catId] ?? '—',
                isCompletedToday: completion[task.taskId] ?? false,
                onComplete: () => _completeTask(ref, task, userAsync.valueOrNull?.uid),
                onTap: () => _openEditTask(context, ref, task, cats),
              );
            },
          );
        },
      ),
      floatingActionButton: cats.isEmpty ? null : FloatingActionButton(
        onPressed: () => _openAddTask(context, ref, cats),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _completeTask(WidgetRef ref, TaskModel task, String? uid) async {
    if (uid == null) return;
    await ref.read(taskServiceProvider).completeTask(task.taskId, task.catId, uid);
    ref.invalidate(todayCompletionMapProvider);
  }

  void _openAddTask(BuildContext context, WidgetRef ref, dynamic cats) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _TaskFormScreen(cats: cats, onSaved: () => ref.invalidate(familyTasksProvider)),
      ),
    );
  }

  void _openEditTask(BuildContext context, WidgetRef ref, TaskModel task, dynamic cats) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _TaskFormScreen(cats: cats, task: task, onSaved: () => ref.invalidate(familyTasksProvider)),
      ),
    );
  }
}

String _repeatTypeLabel(BuildContext context, RepeatType type) {
  final l10n = context.l10n;
  switch (type) {
    case RepeatType.daily: return l10n.repeatDaily;
    case RepeatType.weekly: return l10n.repeatWeekly;
    case RepeatType.monthly: return l10n.repeatMonthly;
    case RepeatType.custom: return l10n.repeatCustom;
  }
}


class _TaskFormScreen extends ConsumerStatefulWidget {
  const _TaskFormScreen({required this.cats, this.task, required this.onSaved});

  final List<dynamic> cats;
  final TaskModel? task;
  final VoidCallback onSaved;

  @override
  ConsumerState<_TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<_TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  CatModel? _selectedCat;
  TaskType _taskType = TaskType.feed;
  RepeatType _repeatType = RepeatType.daily;
  String _scheduledTime = '09:00';
  int _intervalDays = 1;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      final list = widget.cats as List<CatModel>;
      final match = list.where((c) => c.catId == widget.task!.catId).toList();
      _selectedCat = match.isNotEmpty ? match.first : (list.isNotEmpty ? list.first : null);

      _taskType = widget.task!.type;
      _repeatType = widget.task!.repeatType;
      _scheduledTime = widget.task!.scheduledTime;
      _intervalDays = widget.task!.intervalDays;
    } else if (widget.cats.isNotEmpty) {
      _selectedCat = widget.cats.first as CatModel;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedCat == null) return;
    setState(() => _loading = true);
    final taskId = widget.task?.taskId ?? const Uuid().v4();
    final task = TaskModel(
      taskId: taskId,
      catId: _selectedCat!.catId,
      type: _taskType,
      repeatType: _repeatType,
      scheduledTime: _scheduledTime,
      intervalDays: _intervalDays,
      isActive: true,
    );
    try {
      if (widget.task == null) {
        await ref.read(taskServiceProvider).createTask(task);
      } else {
        await ref.read(taskServiceProvider).updateTask(task);
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
    final catList = widget.cats as List<CatModel>;
    return Scaffold(
      appBar: AppBar(title: Text(widget.task == null ? context.l10n.newTask : context.l10n.editTask)),
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
            DropdownButtonFormField<TaskType>(
              key: ValueKey(_taskType),
              initialValue: _taskType,
              decoration: InputDecoration(labelText: context.l10n.type, border: const OutlineInputBorder()),
              items: TaskType.values.map((e) => DropdownMenuItem(value: e, child: Text(TaskCard.taskTypeLabel(context, e)))).toList(),
              onChanged: (v) => setState(() => _taskType = v ?? TaskType.feed),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text('${context.l10n.reminder}: $_scheduledTime'),
              subtitle: Text(_repeatTypeLabel(context, _repeatType)),
              onTap: () async {
                await ReminderDialog.show(
                  context,
                  initialTime: _scheduledTime,
                  initialRepeatType: _repeatType,
                  initialIntervalDays: _intervalDays,
                  onSave: (time, repeat, interval) => setState(() {
                    _scheduledTime = time;
                    _repeatType = repeat;
                    _intervalDays = interval;
                  }),
                );
              },
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

