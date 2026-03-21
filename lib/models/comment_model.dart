import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String commentId;
  final String postId;
  final String authorId;
  final String content;
  final DateTime? createdAt;
  /// 发评论时写入：作者显示名（Google 账号或昵称），用于列表展示，避免只显示 authorId
  final String? authorDisplayName;
  /// 发评论时写入：作者头像 URL，用于列表展示
  final String? authorPhotoUrl;

  const CommentModel({
    required this.commentId,
    required this.postId,
    required this.authorId,
    required this.content,
    this.createdAt,
    this.authorDisplayName,
    this.authorPhotoUrl,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'postId': postId,
      'authorId': authorId,
      'content': content,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
    if (authorDisplayName != null) map['authorDisplayName'] = authorDisplayName;
    if (authorPhotoUrl != null) map['authorPhotoUrl'] = authorPhotoUrl;
    return map;
  }

  static CommentModel fromMap(Map<String, dynamic> map, String commentId) {
    final createdAt = map['createdAt'];
    return CommentModel(
      commentId: commentId,
      postId: map['postId'] as String? ?? '',
      authorId: map['authorId'] as String? ?? '',
      content: map['content'] as String? ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      authorDisplayName: map['authorDisplayName'] as String?,
      authorPhotoUrl: map['authorPhotoUrl'] as String?,
    );
  }

  /// 列表展示用：优先显示作者名，否则 fallback 为 authorId（旧数据）
  String get displayAuthorLabel =>
      (authorDisplayName != null && authorDisplayName!.isNotEmpty) ? authorDisplayName! : authorId;
}

