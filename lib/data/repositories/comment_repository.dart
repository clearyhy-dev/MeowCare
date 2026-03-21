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
      );
      tx.set(commentRef, comment.toMap());
      final postSnap = await tx.get(postRef);
      final currentCount = (postSnap.data()?['commentCount'] as num?)?.toInt() ?? 0;
      tx.update(postRef, {'commentCount': currentCount + 1});
    });
  }
}
