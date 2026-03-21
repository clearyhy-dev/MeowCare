import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/enums.dart';

class HealthLogModel {
  final String logId;
  final String catId;
  final HealthLogType type;
  final double value;
  final String note;
  final DateTime? createdAt;

  const HealthLogModel({
    required this.logId,
    required this.catId,
    required this.type,
    this.value = 0,
    this.note = '',
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'catId': catId,
      'type': type.value,
      'value': value,
      'note': note,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  static HealthLogModel fromMap(Map<String, dynamic> map, String logId) {
    final createdAt = map['createdAt'];
    return HealthLogModel(
      logId: logId,
      catId: map['catId'] as String? ?? '',
      type: HealthLogType.fromString(map['type'] as String?),
      value: (map['value'] as num?)?.toDouble() ?? 0,
      note: map['note'] as String? ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}

class AIRequestModel {
  final String requestId;
  final String uid;
  final String symptom;
  final Severity severity;
  final DateTime? createdAt;

  const AIRequestModel({
    required this.requestId,
    required this.uid,
    required this.symptom,
    this.severity = Severity.green,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'uid': uid,
      'symptom': symptom,
      'severity': severity.value,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  static AIRequestModel fromMap(Map<String, dynamic> map, String requestId) {
    final createdAt = map['createdAt'];
    return AIRequestModel(
      requestId: requestId,
      uid: map['uid'] as String? ?? '',
      symptom: map['symptom'] as String? ?? '',
      severity: Severity.fromString(map['severity'] as String?),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}

