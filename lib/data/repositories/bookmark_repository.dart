import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../models/post_model.dart';

class BookmarkRepository {
  BookmarkRepository() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static String bookmarkId(String uid, String postId) => '${uid}_$postId';

  Future<void> addBookmark({required String uid, required String postId}) async {
    await _firestore.collection(AppConstants.bookmarksCollection).doc(bookmarkId(uid, postId)).set({
      'uid': uid,
      'postId': postId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeBookmark({required String uid, required String postId}) async {
    await _firestore.collection(AppConstants.bookmarksCollection).doc(bookmarkId(uid, postId)).delete();
  }

  Future<bool> isBookmarked(String uid, String postId) async {
    final doc = await _firestore.collection(AppConstants.bookmarksCollection).doc(bookmarkId(uid, postId)).get();
    return doc.exists;
  }

  Future<({List<PostModel> list, DocumentSnapshot? lastDoc})> getBookmarkedPosts({
    required String uid,
    required int limit,
    DocumentSnapshot? startAfter,
    bool onlyPublicInFeed = true,
  }) async {
    Query<Map<String, dynamic>> q = _firestore
        .collection(AppConstants.bookmarksCollection)
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    final snap = await q.get();
    final postIds = snap.docs.map((d) => d.data()['postId'] as String).toList();
    final posts = <PostModel>[];
    for (final id in postIds) {
      final postDoc = await _firestore.collection(AppConstants.postsCollection).doc(id).get();
      if (postDoc.exists && postDoc.data() != null) {
        final p = PostModel.fromMap(postDoc.data()!, postDoc.id);
        if (!onlyPublicInFeed || p.isPubliclyVisibleInFeed) {
          posts.add(p);
        }
      }
    }
    final lastDoc = snap.docs.length == limit && snap.docs.isNotEmpty ? snap.docs.last : null;
    return (list: posts, lastDoc: lastDoc);
  }
}

