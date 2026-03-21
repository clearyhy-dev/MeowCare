import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String type; // 'official' | 'ugc'
  final String status; // 'published' | 'draft' | 'pending' | 'rejected'
  final String title;
  final String summary;
  final String content;
  final String coverUrl;
  /// 可选缩略图；为空时 Feed 使用 [coverUrl]。
  final String thumbnailUrl;
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
  /// 内容语言（如 en、zh）；缺失时 UI 默认 EN。
  final String language;
  /// 显式是否有图；为 null 时由 [displayImageUrl] 是否非空推断。
  final bool? hasImage;
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
    this.thumbnailUrl = '',
    this.breedIds = const [],
    this.topics = const [],
    required this.authorId,
    this.likeCount = 0,
    this.commentCount = 0,
    this.score = 0,
    this.countryCode = '',
    this.redditPermalink = '',
    this.language = 'en',
    this.hasImage,
    this.createdAt,
    this.updatedAt,
  });

  /// 列表展示用图片 URL：优先缩略图，否则封面。
  String get displayImageUrl {
    if (thumbnailUrl.isNotEmpty) return thumbnailUrl;
    return coverUrl;
  }

  /// 是否渲染图片区域（无 URL 或显式 false 则不占位）。
  bool get shouldShowImage {
    final url = displayImageUrl.trim();
    if (url.isEmpty) return false;
    if (hasImage == false) return false;
    return true;
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'status': status,
      'title': title,
      'summary': summary,
      'content': content,
      'coverUrl': coverUrl,
      'thumbnailUrl': thumbnailUrl,
      'breedIds': breedIds,
      'topics': topics,
      'authorId': authorId,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'score': score,
      'countryCode': countryCode,
      'redditPermalink': redditPermalink,
      'language': language,
      if (hasImage != null) 'hasImage': hasImage,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  static PostModel fromMap(Map<String, dynamic> map, String postId) {
    final createdAt = map['createdAt'];
    final updatedAt = map['updatedAt'];
    final hasImageRaw = map['hasImage'];
    bool? hasImage;
    if (hasImageRaw is bool) {
      hasImage = hasImageRaw;
    }
    return PostModel(
      postId: postId,
      type: map['type'] as String? ?? 'ugc',
      status: map['status'] as String? ?? 'draft',
      title: map['title'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      content: map['content'] as String? ?? '',
      coverUrl: map['coverUrl'] as String? ?? '',
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      breedIds: List<String>.from(map['breedIds'] as List? ?? []),
      topics: List<String>.from(map['topics'] as List? ?? []),
      authorId: map['authorId'] as String? ?? '',
      likeCount: (map['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (map['commentCount'] as num?)?.toInt() ?? 0,
      score: (map['score'] as num?)?.toDouble() ?? 0,
      countryCode: map['countryCode'] as String? ?? '',
      redditPermalink: map['redditPermalink'] as String? ?? '',
      language: (map['language'] as String? ?? 'en').toLowerCase(),
      hasImage: hasImage,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
    );
  }
}
