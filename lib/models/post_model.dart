import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String type; // 'official' | 'ugc'
  final String status; // 'published' | 'draft' | 'pending' | 'rejected'
  final String title;
  final String summary;
  final String content;
  final String coverUrl;
  final List<String> breedIds;
  final List<String> topics;
  final String authorId;
  final int likeCount;
  final int commentCount;
  final double score;
  /// 国家/地区码，用于按国家展示 Feed（如 CN、US、JP）
  final String countryCode;
  /// Reddit 原帖链接，用于「View discussion on Reddit」
  final String redditPermalink;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PostModel({
    required this.postId,
    required this.type,
    required this.status,
    required this.title,
    this.summary = '',
    this.content = '',
    this.coverUrl = '',
    this.breedIds = const [],
    this.topics = const [],
    required this.authorId,
    this.likeCount = 0,
    this.commentCount = 0,
    this.score = 0,
    this.countryCode = '',
    this.redditPermalink = '',
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'status': status,
      'title': title,
      'summary': summary,
      'content': content,
      'coverUrl': coverUrl,
      'breedIds': breedIds,
      'topics': topics,
      'authorId': authorId,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'score': score,
      'countryCode': countryCode,
      'redditPermalink': redditPermalink,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  static PostModel fromMap(Map<String, dynamic> map, String postId) {
    final createdAt = map['createdAt'];
    final updatedAt = map['updatedAt'];
    return PostModel(
      postId: postId,
      type: map['type'] as String? ?? 'ugc',
      status: map['status'] as String? ?? 'draft',
      title: map['title'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      content: map['content'] as String? ?? '',
      coverUrl: map['coverUrl'] as String? ?? '',
      breedIds: List<String>.from(map['breedIds'] as List? ?? []),
      topics: List<String>.from(map['topics'] as List? ?? []),
      authorId: map['authorId'] as String? ?? '',
      likeCount: (map['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (map['commentCount'] as num?)?.toInt() ?? 0,
      score: (map['score'] as num?)?.toDouble() ?? 0,
      countryCode: map['countryCode'] as String? ?? '',
      createdAt:
 createdAt is Timestamp ? createdAt.toDate() : null,
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
    );
  }
}
