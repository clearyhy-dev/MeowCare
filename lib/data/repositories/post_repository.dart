import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../models/post_model.dart';

class PostRepository {
  PostRepository() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Fetch published posts with limit and startAfter for pagination.
  /// orderByCreated: true = newest first (publishedAt DESC, 仅已到上线时间)；false = score DESC（热榜，客户端再滤 publishedAt）。
  /// Returns list and the last document snapshot for next page (null if fewer than limit).
  Future<({List<PostModel> list, DocumentSnapshot? lastDoc})> getPosts({
    required int limit,
    DocumentSnapshot? startAfter,
    bool orderByCreated = true,
    List<String>? breedIds,
    List<String>? topics,
    String? countryCode,
  }) async {
    final nowTs = Timestamp.fromDate(DateTime.now().toUtc());
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

    if (orderByCreated) {
      q = q
          .where('publishedAt', isLessThanOrEqualTo: nowTs)
          .orderBy('publishedAt', descending: true);
    } else {
      q = q.orderBy('score', descending: true);
    }

    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    // topic 筛选使用客户端兜底，避免依赖线上尚未创建完成的复合索引导致切换失败。
    final hasTopicFilter = topics != null && topics.isNotEmpty;
    final fetchLimit = orderByCreated
        ? (hasTopicFilter ? limit * 4 : limit)
        : (hasTopicFilter ? limit * 5 : limit * 8);
    q = q.limit(fetchLimit);

    final snap = await q.get();
    var list = snap.docs.map((d) => PostModel.fromMap(d.data(), d.id)).toList();
    if (!orderByCreated) {
      list = list.where((p) => p.isPubliclyVisibleInFeed).toList();
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
  Future<List<PostModel>> getRedditTrendingPosts({int limit = 10}) async {
    final snap = await _firestore
        .collection(AppConstants.postsCollection)
        .where('status', isEqualTo: 'published')
        .where('authorId', isEqualTo: 'reddit')
        .orderBy('score', descending: true)
        .limit(limit * 5)
        .get();
    return snap.docs
        .map((d) => PostModel.fromMap(d.data(), d.id))
        .where((p) => p.isPubliclyVisibleInFeed)
        .take(limit)
        .toList();
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

