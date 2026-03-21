import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/like_repository.dart';
import 'user_provider.dart';


final likeRepositoryProvider = Provider<LikeRepository>((ref) => LikeRepository());

final isLikedProvider = FutureProvider.family<bool, String>((ref, postId) async {
  final uid = ref.watch(currentUserAsyncProvider).valueOrNull?.uid;
  if (uid == null) return false;
  return ref.read(likeRepositoryProvider).isLiked(postId, uid);
});

Future<void> toggleLike(WidgetRef ref, String postId) async {
  final uid = ref.read(currentUserAsyncProvider).valueOrNull?.uid;
  if (uid == null) return;
  await ref.read(likeRepositoryProvider).toggleLike(postId: postId, uid: uid);
  ref.invalidate(isLikedProvider(postId));
}
