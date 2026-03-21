import 'package:flutter/material.dart';

import '../core/constants/enums.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/l10n_ext.dart';
import '../models/task_model.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.catName,
    this.isCompletedToday = false,
    this.showTodayCareLayout = false,
    this.onComplete,
    this.onTap,
  });

  final TaskModel task;
  final String catName;
  final bool isCompletedToday;
  final bool showTodayCareLayout;
  final VoidCallback? onComplete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskTime = task.scheduledTime.isNotEmpty
        ? '${TaskCard.taskTypeLabel(context, task.type)} – ${task.scheduledTime}'
        : TaskCard.taskTypeLabel(context, task.type);
    return AnimatedOpacity(
      opacity: isCompletedToday ? 0.85 : 1,
      duration: const Duration(milliseconds: 200),
      child: Card(
        margin: AppInsets.cardMargin,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: showTodayCareLayout
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.pets, size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(catName, style: theme.textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.todayCare,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Text(taskTime, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: onComplete != null && !isCompletedToday ? onComplete : null,
                          icon: Icon(isCompletedToday ? Icons.check_circle : Icons.check_circle_outline, size: 20),
                          label: Text(context.l10n.markDone),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Checkbox(
                        value: isCompletedToday,
                        onChanged: onComplete != null ? (_) => onComplete!() : null,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(TaskCard.taskTypeLabel(context, task.type), style: theme.textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(catName, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            if (task.scheduledTime.isNotEmpty)
                              Text('${task.scheduledTime} · ${_repeatTypeLabel(context, task.repeatType)}', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
                          ],
                        ),
                      ),
                      Icon(_iconForType(task.type), color: theme.colorScheme.primary),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /// 供任务表单等复用：按当前语言返回任务类型名称
  static String taskTypeLabel(BuildContext context, TaskType type) {
    final l10n = context.l10n;
    switch (type) {
      case TaskType.feed:
        return l10n.feed;
      case TaskType.water:
        return l10n.water;
      case TaskType.litter:
        return l10n.litter;
      case TaskType.grooming:
        return l10n.grooming;
      case TaskType.bath:
        return l10n.bath;
      case TaskType.deworm:
        return l10n.deworm;
      case TaskType.vaccine:
        return l10n.vaccine;
    }
  }


  static String _repeatTypeLabel(BuildContext context, RepeatType type) {
    final l10n = context.l10n;
    switch (type) {
      case RepeatType.daily:
        return l10n.repeatDaily;
      case RepeatType.weekly:
        return l10n.repeatWeekly;
      case RepeatType.monthly:
        return l10n.repeatMonthly;
      case RepeatType.custom:
        return l10n.repeatCustom;
    }
  }

  static IconData _iconForType(TaskType type) {

    switch (type) {
      case TaskType.feed:
        return Icons.restaurant;
      case TaskType.water:
        return Icons.water_drop;
      case TaskType.litter:
        return Icons.cleaning_services;
      case TaskType.grooming:
        return Icons.content_cut;
      case TaskType.bath:
        return Icons.shower;
      case TaskType.deworm:
        return Icons.medical_services;
      case TaskType.vaccine:
        return Icons.vaccines;
    }
  }
}
