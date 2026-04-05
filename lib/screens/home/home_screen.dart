import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n_ext.dart';
import '../../models/task_model.dart';
import '../../providers/cat_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app/app_button.dart';
import '../../widgets/app/empty_state_view.dart';
import '../../widgets/app/error_state_view.dart';
import '../../widgets/app/skeleton_shimmer.dart';
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(context.l10n.appTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.profile,
            icon: const Icon(Icons.person),
            onPressed: () => context.push('${AppRouter.home}settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(familyTasksProvider);
          ref.invalidate(todayCompletionMapProvider);
          ref.invalidate(currentFamilyCatsFutureProvider);
        },
        child: tasksAsync.when(
          loading: () => const _TaskHomeLoadingBody(),
          error: (e, _) => ErrorStateView(
            title: context.l10n.errorGenericRetry,
            message: context.l10n.errorWithMessage(e.toString()),
            retryLabel: context.l10n.retry,
            onRetry: () {
              ref.invalidate(familyTasksProvider);
              ref.invalidate(todayCompletionMapProvider);
              ref.invalidate(currentFamilyCatsFutureProvider);
            },
          ),
          data: (tasks) {
            final user = userAsync.valueOrNull;
            final completion = completionAsync.valueOrNull ?? {};
            final cats = catsAsync.valueOrNull ?? [];
            final catMap = {for (var c in cats) c.catId: c.name};
            if (tasks.isEmpty) {
              return EmptyStateView(
                useScrollView: true,
                message: user == null ? context.l10n.goToSettingsToSignIn : context.l10n.noTasksYet,
                icon: user == null ? Icons.person_outline : Icons.check_circle_outline,
                action: user == null
                    ? AppButton(
                        label: context.l10n.settings,
                        variant: AppButtonVariant.primary,
                        icon: const Icon(Icons.settings_outlined, size: 20),
                        onPressed: () => context.go('${AppRouter.home}settings'),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppButton(
                            label: context.l10n.addCat,
                            variant: AppButtonVariant.primary,
                            icon: const Icon(Icons.pets, size: 20),
                            onPressed: () => context.go('${AppRouter.home}cats'),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppButton(
                            label: context.l10n.aiSymptomSupport,
                            variant: AppButtonVariant.secondary,
                            icon: const Icon(Icons.smart_toy_outlined, size: 20),
                            onPressed: () => context.go('${AppRouter.home}ai'),
                          ),
                        ],
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
                        AppButton(
                          label: context.l10n.allTasks,
                          variant: AppButtonVariant.small,
                          onPressed: () => context.go('${AppRouter.home}tasks'),
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

class _TaskHomeLoadingBody extends StatelessWidget {
  const _TaskHomeLoadingBody();

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
        children: [
          SkeletonLine(width: 120, height: 22, radius: AppRadii.xs),
          const SizedBox(height: AppSpacing.lg),
          const SkeletonNotificationTile(),
          const SizedBox(height: AppSpacing.md),
          const SkeletonNotificationTile(),
          const SizedBox(height: AppSpacing.md),
          const SkeletonNotificationTile(),
        ],
      ),
    );
  }
}

