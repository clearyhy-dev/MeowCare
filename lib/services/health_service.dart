import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/enums.dart';
import '../models/health_model.dart';

class HealthService {
  HealthService._();
  static final HealthService _instance = HealthService._();
  factory HealthService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<HealthLogModel>> getHealthLogsByCatId(String catId, {HealthLogType? type}) async {
    var q = _firestore
        .collection(AppConstants.healthLogsCollection)
        .where('catId', isEqualTo: catId)
        .orderBy('createdAt', descending: true)
        .limit(100);
    if (type != null) {
      q = q.where('type', isEqualTo: type.value);
    }
    final snap = await q.get();
    return snap.docs.map((d) => HealthLogModel.fromMap(d.data(), d.id)).toList();
  }

  Stream<List<HealthLogModel>> watchHealthLogsByCatId(String catId) {
    return _firestore
        .collection(AppConstants.healthLogsCollection)
        .where('catId', isEqualTo: catId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => HealthLogModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addHealthLog(HealthLogModel log) async {
    await _firestore.collection(AppConstants.healthLogsCollection).doc(log.logId).set(log.toMap());
  }

  Future<void> deleteHealthLog(String logId) async {
    await _firestore.collection(AppConstants.healthLogsCollection).doc(logId).delete();
  }
}
