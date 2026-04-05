import 'package:cloud_firestore/cloud_firestore.dart';

import 'post_media_item.dart';

class PostModel {
  final String postId;
  final String type; // 'official' | 'ugc'
  /// 与 Firestore / 后台一致：`published` | `scheduled` | `draft` | `pending` | `rejected`
  final String status;
  final String title;
  final String content;
  /// 自动/编辑推荐摘要；列表可优先展示，与后端 `summary` 对齐。
  final String summary;
  final String coverUrl;
  /// 可选缩略图；为空时 Feed 使用 [coverUrl]。
  final String thumbnailUrl;
  final List<String> breedIds;
  final List<String> topics;
  final String authorId;
  /// 官方帖等：展示用名称（如编辑部）；为空时 UI 可回退应用名。
  final String authorDisplayName;
  final int likeCount;
  final int downvoteCount;
  final int commentCount;
  final double score;
  /// 国家/地区码，用于按国家展示 Feed（如 CN、US、JP）
  final String countryCode;
  /// Reddit 原帖链接，用于「View discussion on Reddit」
  final String redditPermalink;
  /// 发帖时附加的链接（与正文独立，可选）
  final String linkUrl;
  /// 内容语言（如 en、zh）；缺失时 UI 默认 EN。
  final String language;
  /// 显式是否有图；为 null 时由 [displayImageUrl] 是否非空推断。
  final bool? hasImage;
  /// 有序多图 / 视频；为空时回退 [coverUrl]/[thumbnailUrl] 单图逻辑。
  final List<PostMediaItem> mediaItems;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  /// 实际上线时间；已发布且晚于当前时间则不应在 Feed 展示（新数据由后端写入）。
  final DateTime? publishedAt;
  /// 定时发布计划时间（`status == scheduled` 时由后端写入）。
  final DateTime? scheduledPublishAt;

  const PostModel({
    required this.postId,
    required this.type,
    required this.status,
    required this.title,
    this.content = '',
    this.summary = '',
    this.coverUrl = '',
    this.thumbnailUrl = '',
    this.breedIds = const [],
    this.topics = const [],
    required this.authorId,
    this.authorDisplayName = '',
    this.likeCount = 0,
    this.downvoteCount = 0,
    this.commentCount = 0,
    this.score = 0,
    this.countryCode = '',
    this.redditPermalink = '',
    this.linkUrl = '',
    this.language = 'en',
    this.hasImage,
    this.mediaItems = const [],
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
    this.scheduledPublishAt,
  });

  /// 详情页正文：优先用户正文，否则摘要（兼容自动帖）。
  String get displayBody {
    final c = content.trim();
    if (c.isNotEmpty) return content;
    return summary.trim();
  }

  /// Feed 卡片预览：与详情一致，避免仅有 summary 时空白。
  String get listPreviewText {
    final c = content.trim();
    if (c.isNotEmpty) return c;
    return summary.trim();
  }

  /// 列表展示用图片 URL：优先缩略图，否则封面。
  String get displayImageUrl {
    if (mediaItems.isNotEmpty) {
      final first = mediaItems.first;
      if (first.isVideo) {
        final t = first.thumbnailUrl?.trim() ?? '';
        if (t.isNotEmpty) return t;
        return first.url;
      }
      final t = first.thumbnailUrl?.trim() ?? '';
      if (t.isNotEmpty) return t;
      return first.url;
    }
    if (thumbnailUrl.isNotEmpty) return thumbnailUrl;
    return coverUrl;
  }

  /// 是否应对外展示（已发布且 publishedAt 已到；旧数据无 publishedAt 视为可见）。
  bool get isPubliclyVisibleInFeed {
    if (status != 'published') return false;
    final pa = publishedAt;
    if (pa == null) return true;
    final now = DateTime.now().toUtc();
    return !pa.toUtc().isAfter(now);
  }

  /// 是否渲染图片区域（无 URL 或显式 false 则不占位）。
  bool get shouldShowImage {
    if (hasImage == false) return false;
    if (mediaItems.isNotEmpty) return true;
    final url = displayImageUrl.trim();
    if (url.isEmpty) return false;
    return true;
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'status': status,
      'title': title,
      'content': content,
      if (summary.isNotEmpty) 'summary': summary,
      'coverUrl': coverUrl,
      'thumbnailUrl': thumbnailUrl,
      'breedIds': breedIds,
      'topics': topics,
      'authorId': authorId,
      if (authorDisplayName.isNotEmpty) 'authorDisplayName': authorDisplayName,
      'likeCount': likeCount,
      'downvoteCount': downvoteCount,
      'commentCount': commentCount,
      'score': score,
      'countryCode': countryCode,
      'redditPermalink': redditPermalink,
      'language': language,
      if (hasImage != null) 'hasImage': hasImage,
      if (mediaItems.isNotEmpty) 'media': mediaItems.map((e) => e.toMap()).toList(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      if (publishedAt != null) 'publishedAt': Timestamp.fromDate(publishedAt!),
      if (scheduledPublishAt != null) 'scheduledPublishAt': Timestamp.fromDate(scheduledPublishAt!),
    };
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    final out = <String>[];
    for (final e in raw) {
      if (e is String) {
        out.add(e);
      } else if (e != null) {
        out.add(e.toString());
      }
    }
    return out;
  }

  static PostModel fromMap(Map<String, dynamic> map, String postId) {
    final createdAt = map['createdAt'];
    final updatedAt = map['updatedAt'];
    final publishedAtRaw = map['publishedAt'];
    final scheduledRaw = map['scheduledPublishAt'];
    final hasImageRaw = map['hasImage'];
    bool? hasImage;
    if (hasImageRaw is bool) {
      hasImage = hasImageRaw;
    }
    var mediaItems = <PostMediaItem>[];
    final mediaRaw = map['media'];
    if (mediaRaw is List) {
      for (final e in mediaRaw) {
        if (e is Map<String, dynamic>) {
          mediaItems.add(PostMediaItem.fromMap(e));
        } else if (e is Map) {
          mediaItems.add(PostMediaItem.fromMap(Map<String, dynamic>.from(e)));
        }
      }
    }
    final coverFallback = map['coverUrl'] as String? ?? '';
    if (mediaItems.isEmpty && coverFallback.trim().isNotEmpty) {
      final th = map['thumbnailUrl'] as String?;
      mediaItems = [PostMediaItem.image(coverFallback, thumbnailUrl: (th != null && th.isNotEmpty) ? th : null)];
    }
    DateTime? scheduledPublishAt;
    if (scheduledRaw is Timestamp) {
      scheduledPublishAt = scheduledRaw.toDate();
    }

    return PostModel(
      postId: postId,
      type: map['type'] as String? ?? 'ugc',
      status: map['status'] as String? ?? 'draft',
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      coverUrl: map['coverUrl'] as String? ?? '',
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      breedIds: _stringList(map['breedIds']),
      topics: _stringList(map['topics']),
      authorId: map['authorId'] as String? ?? '',
      authorDisplayName: map['authorDisplayName'] as String? ?? '',
      likeCount: (map['likeCount'] as num?)?.toInt() ?? 0,
      downvoteCount: (map['downvoteCount'] as num?)?.toInt() ?? 0,
      commentCount: (map['commentCount'] as num?)?.toInt() ?? 0,
      score: (map['score'] as num?)?.toDouble() ?? 0,
      countryCode: map['countryCode'] as String? ?? '',
      redditPermalink: map['redditPermalink'] as String? ?? '',
      linkUrl: map['linkUrl'] as String? ?? '',
      language: (map['language'] as String? ?? 'en').toLowerCase(),
      hasImage: hasImage,
      mediaItems: mediaItems,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
      publishedAt: publishedAtRaw is Timestamp ? publishedAtRaw.toDate() : null,
      scheduledPublishAt: scheduledPublishAt,
    );
  }
}
