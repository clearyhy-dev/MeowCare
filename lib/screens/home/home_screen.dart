import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n_ext.dart';
import '../../models/task_model.dart';
import '../../providers/cat_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/task_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(familyTasksProvider);
    final completionAsync = ref.watch(todayCompletionMapProvider);
    final catsAsync = ref.watch(currentFamilyCatsFutureProvider);
    final userAsync = ref.watch(currentUserAsyncProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.appTitle),
        actions: [
          IconButton(icon: const Icon(Icons.person), onPressed: () => context.push('${AppRouter.home}settings')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(familyTasksProvider);
          ref.invalidate(todayCompletionMapProvider);
          ref.invalidate(currentFamilyCatsFutureProvider);
        },
        child: tasksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(context.l10n.errorWithMessage(e.toString()))),
          data: (tasks) {
            final user = userAsync.valueOrNull;
            final completion = completionAsync.valueOrNull ?? {};
            final cats = catsAsync.valueOrNull ?? [];
            final catMap = {for (var c in cats) c.catId: c.name};
            if (tasks.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: user == null
                    ? EmptyState(
                        message: context.l10n.goToSettingsToSignIn,
                        icon: Icons.person_outline,
                        action: FilledButton.icon(
                          icon: const Icon(Icons.settings),
                          label: Text(context.l10n.settings),
                          onPressed: () => context.go('${AppRouter.home}settings'),
                        ),
                      )
                    : EmptyState(
                        message: context.l10n.noTasksYet,
                        icon: Icons.check_circle_outline,
                        action: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FilledButton.icon(
                              icon: const Icon(Icons.pets),
                              label: Text(context.l10n.addCat),
                              onPressed: () => context.go('${AppRouter.home}cats'),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.smart_toy_outlined),
                              label: Text(context.l10n.aiSymptomSupport),
                              onPressed: () => context.go('${AppRouter.home}ai'),
                            ),
                          ],
                        ),
                      ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: tasks.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(AppInsets.screenPadding, 8, AppInsets.screenPadding, AppInsets.sectionSpacing / 2),
                    child: Row(

                      children: [
                        Expanded(child: Text(context.l10n.today, style: Theme.of(context).textTheme.titleLarge)),
                        TextButton(
                          onPressed: () => context.go('${AppRouter.home}tasks'),
                          child: Text(context.l10n.allTasks),
                        ),

                      ],
                    ),
                  );
                }
                final task = tasks[i - 1];
                final catName = catMap[task.catId] ?? '—';
                return TaskCard(
                  task: task,
                  catName: catName,
                  isCompletedToday: completion[task.taskId] ?? false,
                  showTodayCareLayout: true,
                  onComplete: () => _completeTask(ref, task, userAsync.valueOrNull?.uid),
                  onTap: () => context.go('${AppRouter.home}tasks'),
                );

              },
            );
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'cat',
            onPressed: () => context.go('${AppRouter.home}cats'),
            child: const Icon(Icons.pets),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'task',
            onPressed: () => context.go('${AppRouter.home}tasks'),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Future<void> _completeTask(WidgetRef ref, TaskModel task, String? uid) async {
    if (uid == null) return;
    await ref.read(taskServiceProvider).completeTask(task.taskId, task.catId, uid);
    ref.invalidate(todayCompletionMapProvider);
  }
}

