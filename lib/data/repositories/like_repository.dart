import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';

class LikeRepository {
  LikeRepository() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static String likeId(String postId, String uid) => '${postId}_$uid';

  Future<int> getMyVote(String postId, String uid) async {
    final doc = await _firestore.collection(AppConstants.likesCollection).doc(likeId(postId, uid)).get();
    if (!doc.exists) return 0;
    final vote = (doc.data()?['vote'] as num?)?.toInt() ?? 1;
    if (vote == -1) return -1;
    return 1;
  }

  Future<void> setVote({required String postId, required String uid, required int vote}) async {
    final targetVote = vote > 0 ? 1 : -1;
    final likeRef = _firestore.collection(AppConstants.likesCollection).doc(likeId(postId, uid));
    final postRef = _firestore.collection(AppConstants.postsCollection).doc(postId);

    await _firestore.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);
      final postSnap = await tx.get(postRef);
      final upCount = (postSnap.data()?['likeCount'] as num?)?.toInt() ?? 0;
      final downCount = (postSnap.data()?['downvoteCount'] as num?)?.toInt() ?? 0;
      final currentVote = likeSnap.exists ? ((likeSnap.data()?['vote'] as num?)?.toInt() ?? 1) : 0;

      if (currentVote == targetVote) {
        tx.delete(likeRef);
        tx.update(postRef, {
          'likeCount': targetVote == 1 ? (upCount > 0 ? upCount - 1 : 0) : upCount,
          'downvoteCount': targetVote == -1 ? (downCount > 0 ? downCount - 1 : 0) : downCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      if (currentVote == 0) {
        tx.set(likeRef, {
          'postId': postId,
          'uid': uid,
          'vote': targetVote,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(postRef, {
          'likeCount': targetVote == 1 ? upCount + 1 : upCount,
          'downvoteCount': targetVote == -1 ? downCount + 1 : downCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      tx.update(likeRef, {'vote': targetVote, 'updatedAt': FieldValue.serverTimestamp()});
      tx.update(postRef, {
        'likeCount': currentVote == 1 ? (upCount > 0 ? upCount - 1 : 0) : upCount + 1,
        'downvoteCount': currentVote == -1 ? (downCount > 0 ? downCount - 1 : 0) : downCount + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

