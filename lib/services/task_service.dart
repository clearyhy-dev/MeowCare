import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/date_utils.dart';
import '../models/task_model.dart';

class TaskService {
  TaskService._();
  static final TaskService _instance = TaskService._();
  factory TaskService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<TaskModel>> getTasksByCatId(String catId) async {
    final snap = await _firestore
        .collection(AppConstants.tasksCollection)
        .where('catId', isEqualTo: catId)
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs.map((d) => TaskModel.fromMap(d.data(), d.id)).toList();
  }

  Future<List<TaskModel>> getTasksByFamilyCatIds(List<String> catIds) async {
    if (catIds.isEmpty) return [];
    final snap = await _firestore
        .collection(AppConstants.tasksCollection)
        .where('catId', whereIn: catIds.length > 10 ? catIds.take(10).toList() : catIds)
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs.map((d) => TaskModel.fromMap(d.data(), d.id)).toList();
  }

  Stream<List<TaskModel>> watchTasksByCatId(String catId) {
    return _firestore
        .collection(AppConstants.tasksCollection)
        .where('catId', isEqualTo: catId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => TaskModel.fromMap(d.data(), d.id)).toList());
  }

  Future<TaskModel?> getTask(String taskId) async {
    final doc = await _firestore.collection(AppConstants.tasksCollection).doc(taskId).get();
    if (!doc.exists || doc.data() == null) return null;
    return TaskModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> createTask(TaskModel task) async {
    await _firestore.collection(AppConstants.tasksCollection).doc(task.taskId).set(task.toMap());
  }

  Future<void> updateTask(TaskModel task) async {
    await _firestore.collection(AppConstants.tasksCollection).doc(task.taskId).update(task.toMap());
  }

  Future<void> deleteTask(String taskId) async {
    await _firestore.collection(AppConstants.tasksCollection).doc(taskId).delete();
  }

  Future<void> completeTask(String taskId, String catId, String completedByUid) async {
    final logRef = _firestore.collection(AppConstants.taskLogsCollection).doc();
    final log = TaskLogModel(
      logId: logRef.id,
      taskId: taskId,
      catId: catId,
      completedBy: completedByUid,
      completedAt: DateTime.now(),
    );
    await logRef.set(log.toMap());
  }

  Future<List<TaskLogModel>> getLogsForTask(String taskId, {DateTime? since}) async {
    var q = _firestore
        .collection(AppConstants.taskLogsCollection)
        .where('taskId', isEqualTo: taskId)
        .orderBy('completedAt', descending: true);
    if (since != null) {
      q = q.where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since));
    }
    final snap = await q.limit(100).get();
    return snap.docs.map((d) => TaskLogModel.fromMap(d.data(), d.id)).toList();
  }

  Future<bool> isTaskCompletedToday(String taskId) async {
    final start = AppDateUtils.startOfToday();
    final snap = await _firestore
        .collection(AppConstants.taskLogsCollection)
        .where('taskId', isEqualTo: taskId)
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<Map<String, bool>> getTodayCompletionMap(List<String> taskIds) async {
    if (taskIds.isEmpty) return {};
    final start = AppDateUtils.startOfToday();
    final end = AppDateUtils.endOfToday();
    final snap = await _firestore
        .collection(AppConstants.taskLogsCollection)
        .where('taskId', whereIn: taskIds)
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('completedAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    final completed = <String>{};
    for (final d in snap.docs) {
      completed.add(d.data()['taskId'] as String? ?? '');
    }
    return {for (final id in taskIds) id: completed.contains(id)};
  }
}
