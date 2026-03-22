import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/enums.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final SubscriptionStatus subscriptionStatus;
  final DateTime? createdAt;
  final String? familyId;
  final bool planStarted;
  final int planProgress;
  /// 未读通知数；仅服务端/Functions 写入，客户端只读。
  final int notificationUnreadCount;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.photoUrl = '',
    this.subscriptionStatus = SubscriptionStatus.free,
    this.createdAt,
    this.familyId,
    this.planStarted = false,
    this.planProgress = 0,
    this.notificationUnreadCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'subscriptionStatus': subscriptionStatus.value,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'familyId': familyId,
      'planStarted': planStarted,
      'planProgress': planProgress,
    };
  }

  static UserModel fromMap(Map<String, dynamic> map, String uid) {
    final createdAt = map['createdAt'];
    return UserModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      subscriptionStatus: SubscriptionStatus.fromString(map['subscriptionStatus'] as String?),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      familyId: map['familyId'] as String?,
      planStarted: map['planStarted'] as bool? ?? false,
      planProgress: (map['planProgress'] as num?)?.toInt() ?? 0,
    );
  }

  UserModel copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    SubscriptionStatus? subscriptionStatus,
    String? familyId,
    bool? planStarted,
    int? planProgress,
    int? notificationUnreadCount,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      createdAt: createdAt,
      familyId: familyId ?? this.familyId,
      planStarted: planStarted ?? this.planStarted,
      planProgress: planProgress ?? this.planProgress,
      notificationUnreadCount: notificationUnreadCount ?? this.notificationUnreadCount,
    );
  }
}

