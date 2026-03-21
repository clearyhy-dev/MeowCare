import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/enums.dart';

class FamilyModel {
  final String familyId;
  final String ownerUid;
  final String inviteCode;
  final DateTime? createdAt;

  const FamilyModel({
    required this.familyId,
    required this.ownerUid,
    required this.inviteCode,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'ownerUid': ownerUid,
      'inviteCode': inviteCode,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  static FamilyModel fromMap(Map<String, dynamic> map, String familyId) {
    final createdAt = map['createdAt'];
    return FamilyModel(
      familyId: familyId,
      ownerUid: map['ownerUid'] as String? ?? '',
      inviteCode: map['inviteCode'] as String? ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}

class FamilyMemberModel {
  final String familyId;
  final String uid;
  final FamilyRole role;
  final DateTime? joinedAt;

  const FamilyMemberModel({
    required this.familyId,
    required this.uid,
    this.role = FamilyRole.member,
    this.joinedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'uid': uid,
      'role': role.value,
      'joinedAt': joinedAt != null ? Timestamp.fromDate(joinedAt!) : FieldValue.serverTimestamp(),
    };
  }

  static FamilyMemberModel fromMap(Map<String, dynamic> map, String uid) {
    final joinedAt = map['joinedAt'];
    return FamilyMemberModel(
      familyId: map['familyId'] as String? ?? '',
      uid: uid,
      role: FamilyRole.fromString(map['role'] as String?),
      joinedAt: joinedAt is Timestamp ? joinedAt.toDate() : null,
    );
  }

  bool get isOwner => role == FamilyRole.owner;
}
