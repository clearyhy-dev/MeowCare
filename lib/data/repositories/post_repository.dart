import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../models/post_model.dart';

class PostRepository {
  PostRepository() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Fetch published posts with limit and startAfter for pagination.
  /// orderByCreated: true = newest first (createdAt DESC), false = score DESC (hot).
  /// Returns list and the last document snapshot for next page (null if fewer than limit).
  Future<({List<PostModel> list, DocumentSnapshot? lastDoc})> getPosts({
    required int limit,
    DocumentSnapshot? startAfter,
    bool orderByCreated = true,
    List<String>? breedIds,
    List<String>? topics,
    String? countryCode,
  }) async {
    Query<Map<String, dynamic>> q = _firestore
        .collection(AppConstants.postsCollection)
        .where('status', isEqualTo: 'published');

    if (countryCode != null && countryCode.isNotEmpty) {
      q = q.where('countryCode', isEqualTo: countryCode);
    }

    if (orderByCreated) {
      q = q.orderBy('createdAt', descending: true);
    } else {
      q = q.orderBy('score', descending: true);
    }

    if (breedIds != null && breedIds.isNotEmpty) {
      q = q.where('breedIds', arrayContains: breedIds.first);
      if (!orderByCreated) q = q.orderBy('score', descending: true);
    } else if (topics != null && topics.isNotEmpty) {
      q = q.where('topics', arrayContains: topics.first);
      q = q.orderBy('score', descending: true);
    }

    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    q = q.limit(limit);

    final snap = await q.get();
    final list = snap.docs.map((d) => PostModel.fromMap(d.data(), d.id)).toList();
    final lastDoc = snap.docs.length == limit && snap.docs.isNotEmpty ? snap.docs.last : null;
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
        .limit(limit)
        .get();
    return snap.docs.map((d) => PostModel.fromMap(d.data(), d.id)).toList();
  }


  Future<PostModel> createPost({
    required String authorId,
    required String title,
    String summary = '',
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
      summary: summary,
      content: content,
      coverUrl: coverUrl,
      breedIds: breedIds,
      topics: topics,
      authorId: authorId,
      likeCount: 0,
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
}

