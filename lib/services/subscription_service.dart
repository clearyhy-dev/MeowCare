import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/enums.dart';

class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService _instance = SubscriptionService._();
  factory SubscriptionService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<SubscriptionStatus> getStatus(String uid) async {
    final doc = await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
    if (!doc.exists || doc.data() == null) return SubscriptionStatus.free;
    return SubscriptionStatus.fromString(doc.data()!['subscriptionStatus'] as String?);
  }

  Future<void> setPro(String uid) async {
    await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
      'subscriptionStatus': SubscriptionStatus.pro.value,
    });
  }

  Future<void> setFree(String uid) async {
    await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
      'subscriptionStatus': SubscriptionStatus.free.value,
    });
  }
}

