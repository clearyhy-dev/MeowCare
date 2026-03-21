import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';

class LikeRepository {
  LikeRepository() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static String likeId(String postId, String uid) => '${postId}_$uid';

  Future<bool> isLiked(String postId, String uid) async {
    final doc = await _firestore.collection(AppConstants.likesCollection).doc(likeId(postId, uid)).get();
    return doc.exists;
  }

  Future<void> toggleLike({required String postId, required String uid}) async {
    final likeRef = _firestore.collection(AppConstants.likesCollection).doc(likeId(postId, uid));
    final postRef = _firestore.collection(AppConstants.postsCollection).doc(postId);

    await _firestore.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);
      final postSnap = await tx.get(postRef);
      final currentCount = (postSnap.data()?['likeCount'] as num?)?.toInt() ?? 0;

      if (likeSnap.exists) {
        tx.delete(likeRef);
        tx.update(postRef, {'likeCount': currentCount > 0 ? currentCount - 1 : 0});
      } else {
        tx.set(likeRef, {
          'postId': postId,
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(postRef, {'likeCount': currentCount + 1});
      }
    });
  }
}

