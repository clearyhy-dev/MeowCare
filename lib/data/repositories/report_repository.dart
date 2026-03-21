import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';

class ReportRepository {
  ReportRepository() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> createReport({
    required String postId,
    required String reporterId,
    required String reason,
  }) async {
    final ref = _firestore.collection(AppConstants.reportsCollection).doc();
    await ref.set({
      'postId': postId,
      'reporterId': reporterId,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'open',
    });
  }
}

