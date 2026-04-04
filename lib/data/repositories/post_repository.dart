import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../models/post_model.dart';

class PostRepository {
  PostRepository() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static String _normalizeLang(String? code) {
    if (code == null || code.isEmpty) return 'en';
    final t = code.trim().toLowerCase();
    if (t.startsWith('zh')) return 'zh';
    return t.length >= 2 ? t.substring(0, 2) : t;
  }

  static bool _postMatchesLanguage(String postLang, String wantLang) {
    return _normalizeLang(postLang) == _normalizeLang(wantLang);
  }

  /// Fetch published posts with limit and startAfter for pagination.
  /// orderByCreated: true = 按 createdAt 最新，客户端再滤 [isPubliclyVisibleInFeed]；false = score DESC（热榜，客户端再滤）。
  /// Returns list and the last document snapshot for next page (null if fewer than limit).
  Future<({List<PostModel> list, DocumentSnapshot? lastDoc})> getPosts({
    required int limit,
    DocumentSnapshot? startAfter,
    bool orderByCreated = true,
    List<String>? breedIds,
    List<String>? topics,
    String? countryCode,
    String? languageCode,
  }) async {
    Query<Map<String, dynamic>> q = _firestore
        .collection(AppConstants.postsCollection)
        .where('status', isEqualTo: 'published');

    if (countryCode != null && countryCode.isNotEmpty) {
      q = q.where('countryCode', isEqualTo: countryCode);
    }

    // UI 当前为二选一筛选：breed 或 topic（选择其一会清空另一项）。
    if (breedIds != null && breedIds.isNotEmpty) {
      q = q.where('breedIds', arrayContains: breedIds.first);
    }

    // Latest：按 createdAt，避免 `publishedAt` 缺失的已发布帖被 Firestore 不等式整段排除。
    // 定时上线帖在客户端用 [PostModel.isPubliclyVisibleInFeed] 过滤（与 Hot 一致）。
    if (orderByCreated) {
      q = q.orderBy('createdAt', descending: true);
    } else {
      q = q.orderBy('score', descending: true);
    }

    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    // topic / language 筛选使用客户端兜底，避免复合索引与分页不一致。
    final hasTopicFilter = topics != null && topics.isNotEmpty;
    final wantLang = languageCode != null && languageCode.isNotEmpty
        ? _normalizeLang(languageCode)
        : null;
    final hasLangFilter = wantLang != null;
    final fetchLimit = orderByCreated
        ? (hasTopicFilter
            ? limit * 4
            : hasLangFilter
                ? limit * 5
                : limit * 3)
        : (hasTopicFilter
            ? limit * 5
            : hasLangFilter
                ? limit * 10
                : limit * 8);
    q = q.limit(fetchLimit);

    final snap = await q.get();
    var list = snap.docs.map((d) => PostModel.fromMap(d.data(), d.id)).toList();
    list = list.where((p) => p.isPubliclyVisibleInFeed).toList();
    final langFilter = wantLang;
    if (langFilter != null) {
      list = list.where((p) => _postMatchesLanguage(p.language, langFilter)).toList();
    }
    if (hasTopicFilter) {
      final wanted = topics.first;
      list = list.where((p) => p.topics.contains(wanted)).take(limit).toList();
    } else if (list.length > limit) {
      list = list.take(limit).toList();
    }
    final lastDoc = snap.docs.length == fetchLimit && snap.docs.isNotEmpty ? snap.docs.last : null;
    return (list: list, lastDoc: lastDoc);
  }


  Future<PostModel?> getPost(String postId) async {
    final doc = await _firestore.collection(AppConstants.postsCollection).doc(postId).get();
    if (!doc.exists || doc.data() == null) return null;
    return PostModel.fromMap(doc.data()!, doc.id);
  }

  /// Reddit-sourced posts for the "Trending from Reddit" block (authorId == 'reddit', by score).
  Future<List<PostModel>> getRedditTrendingPosts({
    int limit = 10,
    String? languageCode,
  }) async {
    final wantLang = languageCode != null && languageCode.isNotEmpty
        ? _normalizeLang(languageCode)
        : null;
    final fetch = wantLang != null ? limit * 8 : limit * 5;
    final snap = await _firestore
        .collection(AppConstants.postsCollection)
        .where('status', isEqualTo: 'published')
        .where('authorId', isEqualTo: 'reddit')
        .orderBy('score', descending: true)
        .limit(fetch)
        .get();
    var rows = snap.docs
        .map((d) => PostModel.fromMap(d.data(), d.id))
        .where((p) => p.isPubliclyVisibleInFeed)
        .toList();
    if (wantLang != null) {
      rows = rows.where((p) => _postMatchesLanguage(p.language, wantLang)).take(limit).toList();
    } else {
      rows = rows.take(limit).toList();
    }
    return rows;
  }


  Future<PostModel> createPost({
    required String authorId,
    required String title,
    String content = '',
    String coverUrl = '',
    List<String> breedIds = const [],
    List<String> topics = const [],
    String status = 'pending',
    String countryCode = '',
    String language = 'en',
    bool? hasImage,
  }) async {
    final ref = _firestore.collection(AppConstants.postsCollection).doc();
    final inferredHasImage = hasImage ?? coverUrl.trim().isNotEmpty;
    final post = PostModel(
      postId: ref.id,
      type: 'ugc',
      status: status,
      title: title,
      content: content,
      coverUrl: coverUrl,
      breedIds: breedIds,
      topics: topics,
      authorId: authorId,
      likeCount: 0,
      downvoteCount: 0,
      commentCount: 0,
      score: 0,
      countryCode: countryCode,
      language: language.isNotEmpty ? language.toLowerCase() : 'en',
      hasImage: inferredHasImage ? true : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.set(post.toMap());
    return post;
  }

  /// 发帖后上传封面图成功时更新 `coverUrl` / `hasImage`。
  Future<void> updatePostCover({
    required String postId,
    required String coverUrl,
  }) async {
    await _firestore.collection(AppConstants.postsCollection).doc(postId).update({
      'coverUrl': coverUrl,
      'hasImage': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Current user's posts for a given [status] (draft / pending / published / rejected).
  Future<({List<PostModel> list, DocumentSnapshot? lastDoc})> getMyPosts({
    required String authorId,
    required String status,
    required int limit,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> q = _firestore
        .collection(AppConstants.postsCollection)
        .where('authorId', isEqualTo: authorId)
        .where('status', isEqualTo: status)
        .orderBy('updatedAt', descending: true)
        .limit(limit);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    final snap = await q.get();
    final list = snap.docs.map((d) => PostModel.fromMap(d.data(), d.id)).toList();
    final lastDoc = snap.docs.length == limit && snap.docs.isNotEmpty ? snap.docs.last : null;
    return (list: list, lastDoc: lastDoc);
  }
}

