import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task_model.dart';
import '../services/task_service.dart';
import 'cat_provider.dart';

final taskServiceProvider = Provider<TaskService>((ref) => TaskService());

final familyTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  final cats = await ref.watch(currentFamilyCatsFutureProvider.future);
  final catIds = cats.map((c) => c.catId).toList();
  if (catIds.isEmpty) return [];
  return ref.read(taskServiceProvider).getTasksByFamilyCatIds(catIds);
});

final todayCompletionMapProvider = FutureProvider<Map<String, bool>>((ref) async {
  final tasks = await ref.watch(familyTasksProvider.future);
  final taskIds = tasks.map((t) => t.taskId).toList();
  if (taskIds.isEmpty) return {};
  return ref.read(taskServiceProvider).getTodayCompletionMap(taskIds);
});
