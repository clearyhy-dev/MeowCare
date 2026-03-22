import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../models/comment_model.dart';

class CommentRepository {
  CommentRepository() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<({List<CommentModel> list, DocumentSnapshot? lastDoc})> getComments({
    required String postId,
    required int limit,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> q = _firestore
        .collection(AppConstants.commentsCollection)
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    final snap = await q.get();
    final list = snap.docs.map((d) => CommentModel.fromMap(d.data(), d.id)).toList();
    final lastDoc = snap.docs.length == limit && snap.docs.isNotEmpty ? snap.docs.last : null;
    return (list: list, lastDoc: lastDoc);
  }

  Future<void> addComment({
    required String postId,
    required String authorId,
    required String content,
    String? authorDisplayName,
    String? authorPhotoUrl,
    String? parentCommentId,
    String? replyToAuthor,
  }) async {
    final postRef = _firestore.collection(AppConstants.postsCollection).doc(postId);
    final commentsRef = _firestore.collection(AppConstants.commentsCollection);

    await _firestore.runTransaction((tx) async {
      final commentRef = commentsRef.doc();
      final comment = CommentModel(
        commentId: commentRef.id,
        postId: postId,
        authorId: authorId,
        content: content,
        createdAt: DateTime.now(),
        authorDisplayName: authorDisplayName,
        authorPhotoUrl: authorPhotoUrl,
        parentCommentId: parentCommentId,
        replyToAuthor: replyToAuthor,
      );
      tx.set(commentRef, comment.toMap());
      final postSnap = await tx.get(postRef);
      final currentCount = (postSnap.data()?['commentCount'] as num?)?.toInt() ?? 0;
      tx.update(postRef, {'commentCount': currentCount + 1});
    });
  }

  Future<({List<CommentModel> comments, Map<String, String> postTitles, DocumentSnapshot? lastDoc})>
      getMyCommentsWithPostTitles({
    required String authorId,
    required int limit,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> q = _firestore
        .collection(AppConstants.commentsCollection)
        .where('authorId', isEqualTo: authorId)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    final snap = await q.get();
    final comments = snap.docs.map((d) => CommentModel.fromMap(d.data(), d.id)).toList();
    final postIds = comments.map((c) => c.postId).toSet().toList();
    final postTitles = <String, String>{};
    const chunk = 30;
    for (var i = 0; i < postIds.length; i += chunk) {
      final end = i + chunk > postIds.length ? postIds.length : i + chunk;
      final slice = postIds.sublist(i, end);
      final docs = await Future.wait(
        slice.map((id) => _firestore.collection(AppConstants.postsCollection).doc(id).get()),
      );
      for (final doc in docs) {
        if (doc.exists && doc.data() != null) {
          final t = doc.data()!['title'] as String? ?? '';
          postTitles[doc.id] = t;
        }
      }
    }
    final lastDoc = snap.docs.length == limit && snap.docs.isNotEmpty ? snap.docs.last : null;
    return (comments: comments, postTitles: postTitles, lastDoc: lastDoc);
  }
}
