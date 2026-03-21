import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';

class UserRepository {
  UserRepository() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> setPlanStarted(String uid) async {
    await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
      'planStarted': true,
      'planProgress': 0,
    });
  }

  Future<void> setPlanProgress(String uid, int dayIndex) async {
    await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
      'planProgress': dayIndex,
    });
  }
}

