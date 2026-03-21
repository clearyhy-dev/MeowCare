import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/enums.dart';

class TaskModel {
  final String taskId;
  final String catId;
  final TaskType type;
  final RepeatType repeatType;
  final String scheduledTime; // HH:mm
  final int intervalDays;
  final bool isActive;

  const TaskModel({
    required this.taskId,
    required this.catId,
    required this.type,
    this.repeatType = RepeatType.daily,
    this.scheduledTime = '09:00',
    this.intervalDays = 1,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'catId': catId,
      'type': type.value,
      'repeatType': repeatType.value,
      'scheduledTime': scheduledTime,
      'intervalDays': intervalDays,
      'isActive': isActive,
    };
  }

  static TaskModel fromMap(Map<String, dynamic> map, String taskId) {
    return TaskModel(
      taskId: taskId,
      catId: map['catId'] as String? ?? '',
      type: TaskType.fromString(map['type'] as String?),
      repeatType: RepeatType.fromString(map['repeatType'] as String?),
      scheduledTime: map['scheduledTime'] as String? ?? '09:00',
      intervalDays: map['intervalDays'] as int? ?? 1,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  TaskModel copyWith({
    String? catId,
    TaskType? type,
    RepeatType? repeatType,
    String? scheduledTime,
    int? intervalDays,
    bool? isActive,
  }) {
    return TaskModel(
      taskId: taskId,
      catId: catId ?? this.catId,
      type: type ?? this.type,
      repeatType: repeatType ?? this.repeatType,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      intervalDays: intervalDays ?? this.intervalDays,
      isActive: isActive ?? this.isActive,
    );
  }
}

class TaskLogModel {
  final String logId;
  final String taskId;
  final String catId;
  final String completedBy;
  final DateTime? completedAt;

  const TaskLogModel({
    required this.logId,
    required this.taskId,
    required this.catId,
    required this.completedBy,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'taskId': taskId,
      'catId': catId,
      'completedBy': completedBy,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : FieldValue.serverTimestamp(),
    };
  }

  static TaskLogModel fromMap(Map<String, dynamic> map, String logId) {
    final completedAt = map['completedAt'];
    return TaskLogModel(
      logId: logId,
      taskId: map['taskId'] as String? ?? '',
      catId: map['catId'] as String? ?? '',
      completedBy: map['completedBy'] as String? ?? '',
      completedAt: completedAt is Timestamp ? completedAt.toDate() : null,
    );
  }
}
