import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../data/repositories/post_repository.dart';
import '../models/post_model.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) => PostRepository());

class FeedState {
  final List<PostModel> posts;
  final DocumentSnapshot? lastDoc;
  final bool loading;
  final bool hasMore;
  final String? error;

  const FeedState({
    this.posts = const [],
    this.lastDoc,
    this.loading = false,
    this.hasMore = true,
    this.error,
  });
}

class FeedNotifier extends StateNotifier<FeedState> {
  FeedNotifier(this._repo) : super(const FeedState());

  final PostRepository _repo;

  bool _orderByCreated = true;
  String? _topic;
  String? _countryCode;
  String? _breedId;

  Future<void> loadFirst({
    bool orderByCreated = true,
    String? topic,
    String? countryCode,
    String? breedId,
  }) async {
    if (state.loading) return;
    state = const FeedState(loading: true, error: null);
    _orderByCreated = orderByCreated;
    _topic = topic;
    _countryCode = countryCode;
    _breedId = breedId;
    final topics = topic != null ? [topic] : null;
    final breedIds = _breedId != null && _breedId!.isNotEmpty ? [_breedId!] : null;
    try {
      final result = await _repo.getPosts(
        limit: AppConstants.feedPageSize,
        orderByCreated: _orderByCreated,
        breedIds: breedIds,
        topics: topics,
        countryCode: _countryCode,
      );
      state = FeedState(
        posts: result.list,
        lastDoc: result.lastDoc,
        hasMore: result.list.length == AppConstants.feedPageSize,
      );
    } catch (e) {
      state = FeedState(posts: [], hasMore: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) return;
    state = FeedState(
      posts: state.posts,
      lastDoc: state.lastDoc,
      loading: true,
      hasMore: state.hasMore,
    );
    final breedIds = _breedId != null ? [_breedId!] : null;
    final topics = _topic != null ? [_topic!] : null;
    final result = await _repo.getPosts(
      limit: AppConstants.feedPageSize,
      startAfter: state.lastDoc,
      orderByCreated: _orderByCreated,
      breedIds: breedIds,
      topics: topics,
      countryCode: _countryCode,
    );

    state = FeedState(
      posts: [...state.posts, ...result.list],
      lastDoc: result.lastDoc,
      hasMore: result.list.length == AppConstants.feedPageSize,
    );
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier(ref.read(postRepositoryProvider));
});

/// Reddit trending posts for the home feed "Trending from Reddit" block.
final redditTrendingProvider = FutureProvider<List<PostModel>>((ref) async {
  final repo = ref.read(postRepositoryProvider);
  return repo.getRedditTrendingPosts(limit: 10);
});

