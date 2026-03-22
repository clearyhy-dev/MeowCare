import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../core/constants/app_constants.dart';
import '../../models/notification_model.dart';

class NotificationRepository {
  NotificationRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-east1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<List<NotificationModel>> watchNotifications(String uid, {int limit = 50}) {
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .where('recipientUserId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => NotificationModel.fromMap(d.data(), d.id)).toList());
  }

  Future<({List<NotificationModel> list, DocumentSnapshot? lastDoc})> getNotificationsPage({
    required String uid,
    required int limit,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> q = _firestore
        .collection(AppConstants.notificationsCollection)
        .where('recipientUserId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    final snap = await q.get();
    final list = snap.docs.map((d) => NotificationModel.fromMap(d.data(), d.id)).toList();
    final lastDoc = snap.docs.length == limit && snap.docs.isNotEmpty ? snap.docs.last : null;
    return (list: list, lastDoc: lastDoc);
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _functions.httpsCallable('markNotificationRead').call(<String, dynamic>{
      'notificationId': notificationId,
    });
  }

  Future<int> markAllNotificationsRead() async {
    final result = await _functions.httpsCallable('markAllNotificationsRead').call();
    final data = result.data;
    if (data is Map && data['updated'] is num) {
      return (data['updated'] as num).toInt();
    }
    return 0;
  }
}
