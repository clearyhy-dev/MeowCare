import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String notificationId;
  final String recipientUserId;
  final String type;
  final String? actorUserId;
  final String actorDisplayName;
  final String targetPostId;
  final String? targetCommentId;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? readAt;

  const NotificationModel({
    required this.notificationId,
    required this.recipientUserId,
    required this.type,
    this.actorUserId,
    this.actorDisplayName = '',
    required this.targetPostId,
    this.targetCommentId,
    this.title = '',
    this.body = '',
    this.isRead = false,
    this.createdAt,
    this.readAt,
  });

  static NotificationModel fromMap(Map<String, dynamic> map, String id) {
    final createdAt = map['createdAt'];
    final readAt = map['readAt'];
    return NotificationModel(
      notificationId: id,
      recipientUserId: map['recipientUserId'] as String? ?? '',
      type: map['type'] as String? ?? 'system',
      actorUserId: map['actorUserId'] as String?,
      actorDisplayName: map['actorDisplayName'] as String? ?? '',
      targetPostId: map['targetPostId'] as String? ?? '',
      targetCommentId: map['targetCommentId'] as String?,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      isRead: map['isRead'] as bool? ?? false,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      readAt: readAt is Timestamp ? readAt.toDate() : null,
    );
  }
}
