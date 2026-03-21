import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../data/repositories/comment_repository.dart';
import '../models/comment_model.dart';

final commentRepositoryProvider = Provider<CommentRepository>((ref) => CommentRepository());

final commentsProvider = FutureProvider.family<({List<CommentModel> list, DocumentSnapshot? lastDoc}), ({String postId, DocumentSnapshot? startAfter})>((ref, key) async {
  return ref.read(commentRepositoryProvider).getComments(
        postId: key.postId,
        limit: AppConstants.feedPageSize,
        startAfter: key.startAfter,
      );
});
