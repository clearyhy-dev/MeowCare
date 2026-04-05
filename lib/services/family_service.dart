import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/enums.dart';
import '../core/errors/family_limit_exception.dart';
import '../models/family_model.dart';

class FamilyService {
  FamilyService._();
  static final FamilyService _instance = FamilyService._();
  factory FamilyService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = DateTime.now().millisecondsSinceEpoch;
    return List.generate(6, (i) => chars[(r + i) % chars.length]).join();
  }

  Future<FamilyModel> createFamily(String ownerUid) async {
    final familyRef = _firestore.collection(AppConstants.familiesCollection).doc();
    final familyId = familyRef.id;
    final inviteCode = _generateInviteCode();
    final family = FamilyModel(
      familyId: familyId,
      ownerUid: ownerUid,
      inviteCode: inviteCode,
      createdAt: DateTime.now(),
    );
    await familyRef.set(family.toMap());
    await familyRef.collection(AppConstants.membersSubcollection).doc(ownerUid).set(
          FamilyMemberModel(
            familyId: familyId,
            uid: ownerUid,
            role: FamilyRole.owner,
            joinedAt: DateTime.now(),
          ).toMap(),
        );
    await _firestore.collection(AppConstants.usersCollection).doc(ownerUid).update({'familyId': familyId});
    return family;
  }

  Future<FamilyModel?> joinFamilyByInviteCode(String inviteCode, String uid) async {
    final q = await _firestore
        .collection(AppConstants.familiesCollection)
        .where('inviteCode', isEqualTo: inviteCode.trim().toUpperCase())
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    final familyDoc = q.docs.first;
    final familyId = familyDoc.id;
    final family = FamilyModel.fromMap(familyDoc.data(), familyId);
    final memberCount = await getMemberCount(familyId);
    if (memberCount >= AppConstants.freeMaxMembers) {
      final ownerDoc = await _firestore.collection(AppConstants.usersCollection).doc(family.ownerUid).get();
      final ownerPro = ownerDoc.exists &&
          ownerDoc.data() != null &&
          SubscriptionStatus.fromString(ownerDoc.data()!['subscriptionStatus'] as String?) == SubscriptionStatus.pro;
      if (!ownerPro) throw FamilyLimitReachedException();
    }
    await familyDoc.reference.collection(AppConstants.membersSubcollection).doc(uid).set(

          FamilyMemberModel(
            familyId: familyId,
            uid: uid,
            role: FamilyRole.member,
            joinedAt: DateTime.now(),
          ).toMap(),
        );
    await _firestore.collection(AppConstants.usersCollection).doc(uid).update({'familyId': familyId});
    return FamilyModel.fromMap(familyDoc.data(), familyId);
  }

  Future<FamilyModel?> getFamily(String familyId) async {
    final doc = await _firestore.collection(AppConstants.familiesCollection).doc(familyId).get();
    if (!doc.exists || doc.data() == null) return null;
    return FamilyModel.fromMap(doc.data()!, doc.id);
  }

  Stream<FamilyModel?> watchFamily(String familyId) {
    return _firestore.collection(AppConstants.familiesCollection).doc(familyId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return FamilyModel.fromMap(snap.data()!, snap.id);
    });
  }

  Future<List<FamilyMemberModel>> getMembers(String familyId) async {
    final snap = await _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.membersSubcollection)
        .get();
    return snap.docs.map((d) => FamilyMemberModel.fromMap(d.data(), d.id)).toList();
  }

  /// Members with display names from [AppConstants.usersCollection] for settings / dialogs.
  Future<List<FamilyMemberDisplay>> getMembersWithDisplayNames(String familyId) async {
    final members = await getMembers(familyId);
    if (members.isEmpty) return [];
    final rows = await Future.wait(members.map((m) async {
      final snap = await _firestore.collection(AppConstants.usersCollection).doc(m.uid).get();
      var name = m.uid;
      if (snap.exists && snap.data() != null) {
        final dn = snap.data()!['displayName'];
        if (dn is String && dn.trim().isNotEmpty) name = dn.trim();
      }
      return FamilyMemberDisplay(member: m, displayName: name);
    }));
    return rows;
  }

  Future<void> removeMember(String familyId, String memberUid, String requesterUid) async {
    final familyDoc = _firestore.collection(AppConstants.familiesCollection).doc(familyId);
    final family = await getFamily(familyId);
    if (family == null || family.ownerUid != requesterUid) throw StateError('Only owner can remove members');
    await familyDoc.collection(AppConstants.membersSubcollection).doc(memberUid).delete();
    await _firestore.collection(AppConstants.usersCollection).doc(memberUid).update({'familyId': FieldValue.delete()});
  }

  Future<void> leaveFamily(String familyId, String uid) async {
    final family = await getFamily(familyId);
    if (family == null) return;
    if (family.ownerUid == uid) throw StateError('Owner cannot leave; transfer or delete family first');
    await _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.membersSubcollection)
        .doc(uid)
        .delete();
    await _firestore.collection(AppConstants.usersCollection).doc(uid).update({'familyId': FieldValue.delete()});
  }

  Future<int> getMemberCount(String familyId) async {
    final snap = await _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.membersSubcollection)
        .get();
    return snap.docs.length;
  }
}
