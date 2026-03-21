import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/like_repository.dart';
import 'user_provider.dart';


final likeRepositoryProvider = Provider<LikeRepository>((ref) => LikeRepository());

class VoteUiState {
  final int vote;
  final int upDelta;
  final int downDelta;
  final bool pending;

  const VoteUiState({
    required this.vote,
    required this.upDelta,
    required this.downDelta,
    required this.pending,
  });
}

final voteUiStateProvider = StateProvider.family<VoteUiState?, String>((ref, postId) => null);

final myVoteProvider = FutureProvider.family<int, String>((ref, postId) async {
  final uid = ref.watch(currentUserAsyncProvider).valueOrNull?.uid;
  if (uid == null) return 0;
  return ref.read(likeRepositoryProvider).getMyVote(postId, uid);
});

final myEffectiveVoteProvider = Provider.family<int, String>((ref, postId) {
  final ui = ref.watch(voteUiStateProvider(postId));
  if (ui != null) return ui.vote;
  return ref.watch(myVoteProvider(postId)).valueOrNull ?? 0;
});

void clearVoteUiState(WidgetRef ref, String postId) {
  ref.read(voteUiStateProvider(postId).notifier).state = null;
}

Future<void> toggleUpvote(WidgetRef ref, String postId) async {
  await _toggleVote(ref, postId, 1);
}

Future<void> toggleDownvote(WidgetRef ref, String postId) async {
  await _toggleVote(ref, postId, -1);
}

Future<void> _toggleVote(WidgetRef ref, String postId, int target) async {
  final uid = ref.read(currentUserAsyncProvider).valueOrNull?.uid;
  if (uid == null) return;
  final current = ref.read(myEffectiveVoteProvider(postId));
  final newVote = current == target ? 0 : target;

  final upDelta = (newVote == 1 ? 1 : 0) - (current == 1 ? 1 : 0);
  final downDelta = (newVote == -1 ? 1 : 0) - (current == -1 ? 1 : 0);

  ref.read(voteUiStateProvider(postId).notifier).state = VoteUiState(
        vote: newVote,
        upDelta: upDelta,
        downDelta: downDelta,
        pending: true,
      );
  try {
    await ref.read(likeRepositoryProvider).setVote(postId: postId, uid: uid, vote: target);
    ref.read(voteUiStateProvider(postId).notifier).state = VoteUiState(
          vote: newVote,
          upDelta: upDelta,
          downDelta: downDelta,
          pending: false,
        );
    ref.invalidate(myVoteProvider(postId));
  } catch (_) {
    ref.read(voteUiStateProvider(postId).notifier).state = null;
    rethrow;
  }
}
