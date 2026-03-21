import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/bookmark_repository.dart';
import '../models/post_model.dart';
import 'user_provider.dart';

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) => BookmarkRepository());

final isBookmarkedProvider = FutureProvider.family<bool, String>((ref, postId) async {
  final uid = ref.watch(currentUserAsyncProvider).valueOrNull?.uid;
  if (uid == null) return false;
  return ref.read(bookmarkRepositoryProvider).isBookmarked(uid, postId);
});

final bookmarkedPostsProvider = FutureProvider<({List<PostModel> list, DocumentSnapshot? lastDoc})>((ref) async {
  final uid = ref.watch(currentUserAsyncProvider).valueOrNull?.uid;
  if (uid == null) return (list: <PostModel>[], lastDoc: null);
  return ref.read(bookmarkRepositoryProvider).getBookmarkedPosts(uid: uid, limit: 20);
});


Future<void> toggleBookmark(WidgetRef ref, String postId) async {
  final uid = ref.read(currentUserAsyncProvider).valueOrNull?.uid;
  if (uid == null) return;
  final repo = ref.read(bookmarkRepositoryProvider);
  final exists = await repo.isBookmarked(uid, postId);
  if (exists) {
    await repo.removeBookmark(uid: uid, postId: postId);
  } else {
    await repo.addBookmark(uid: uid, postId: postId);
  }
  ref.invalidate(isBookmarkedProvider);
}

