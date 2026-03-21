import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/app_feedback.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/topic_l10n.dart';
import '../../providers/feed_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app/app_empty_state.dart';
import '../../widgets/feed/feed_control_bar.dart';
import '../../widgets/post/post_card.dart';
import '../../widgets/post/post_card_skeleton.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  String _searchText = '';
  bool _latestSelected = true;
  String? _selectedTopic;
  static const _topics = ['care', 'health', 'feeding', 'behavior'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final country = ref.read(appCountryProvider).valueOrNull;
      ref.read(feedProvider.notifier).loadFirst(orderByCreated: true, countryCode: country);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged({bool? latestSelected}) {
    if (latestSelected != null) {
      _latestSelected = latestSelected;
    }
    final country = ref.read(appCountryProvider).valueOrNull;
    ref.read(feedProvider.notifier).loadFirst(
      orderByCreated: _latestSelected,
      topic: _selectedTopic,
      countryCode: country,
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final user = ref.watch(currentUserAsyncProvider).valueOrNull;
    ref.listen<AsyncValue<String?>>(appCountryProvider, (prev, next) {
      if (!next.hasValue) return;
      final nextCountry = next.valueOrNull;
      if (prev?.valueOrNull == nextCountry) return;
      ref.read(feedProvider.notifier).loadFirst(
        orderByCreated: _latestSelected,
        topic: _selectedTopic,
        countryCode: nextCountry,
      );
    });
    final posts = feedState.posts;
    final normalizedSearch = _searchText.trim().toLowerCase();
    final visiblePosts = normalizedSearch.isEmpty
        ? posts
        : posts.where((post) {
            final title = post.title.toLowerCase();
            final content = post.content.toLowerCase();
            final topics = post.topics.join(' ').toLowerCase();
            return title.contains(normalizedSearch) ||
                content.contains(normalizedSearch) ||
                topics.contains(normalizedSearch);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.feed),
        actions: [
          if (user != null) IconButton(icon: const Icon(Icons.pets), onPressed: () => context.push('${AppRouter.home}my-cats')),
          IconButton(icon: const Icon(Icons.person), onPressed: () => context.push('${AppRouter.home}settings')),
          if (user != null)
            IconButton(icon: const Icon(Icons.add), onPressed: () => context.push('${AppRouter.home}post/create')),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(94),
          child: FeedControlBar(
            searchController: _searchController,
            searchHintText: context.l10n.searchPostsHint,
            onSearchChanged: (value) => setState(() => _searchText = value),
            latestSelected: _latestSelected,
            latestLabel: context.l10n.latest,
            hotLabel: context.l10n.hot,
            onSelectLatest: () {
              if (_latestSelected) return;
              AppFeedback.selection();
              setState(() => _latestSelected = true);
              _onFilterChanged(latestSelected: true);
            },
            onSelectHot: () {
              if (!_latestSelected) return;
              AppFeedback.selection();
              setState(() => _latestSelected = false);
              _onFilterChanged(latestSelected: false);
            },
            selectedTopic: _selectedTopic,
            topicIds: _topics,
            allTopicsLabel: context.l10n.allTopics,
            topicLabelBuilder: (topicId) => topicLabel(context, topicId),
            onTopicSelect: (id) {
              AppFeedback.selection();
              setState(() => _selectedTopic = id);
              _onFilterChanged();
            },
          ),
        ),
      ),
      body: feedState.error != null && feedState.posts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.l10n.feedLoadFailed,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      final country = ref.read(appCountryProvider).valueOrNull;
                      ref.read(feedProvider.notifier).loadFirst(
                        orderByCreated: _latestSelected,
                        topic: _selectedTopic,
                        countryCode: country,
                      );
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(context.l10n.retry),
                  ),
                ],
              ),
            )
          : feedState.loading && feedState.posts.isEmpty
              ? const _FeedLoadingSkeleton()
              : (!feedState.loading && posts.isEmpty)
                  ? AppEmptyState(message: context.l10n.feedNoContent, icon: Icons.forum_outlined)
                  : (!feedState.loading && posts.isNotEmpty && visiblePosts.isEmpty)
                      ? AppEmptyState(message: context.l10n.noResultFound, icon: Icons.search_off_rounded)
                  : RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(redditTrendingProvider);
                    final country = ref.read(appCountryProvider).valueOrNull;
                    await ref.read(feedProvider.notifier).loadFirst(
                      orderByCreated: _latestSelected,
                      topic: _selectedTopic,
                      countryCode: country,
                    );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                    itemCount: 1 + visiblePosts.length + (feedState.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: _RedditTrendingBlock(
                            onTapPost: (postId) => context.push('${AppRouter.postDetail}/$postId'),
                          ),
                        );
                      }
                      final postIndex = index - 1;
                      final postCount = visiblePosts.length;
                      if (postIndex >= postCount) {
                        if (postIndex == postCount) {
                          ref.read(feedProvider.notifier).loadMore();
                        }
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (postIndex < 0 || postIndex >= postCount) {
                        return const SizedBox.shrink();
                      }
                      final post = visiblePosts[postIndex];
                      return PostCard(
                        post: post,
                        onOpenPost: () => context.push('${AppRouter.postDetail}/${post.postId}'),
                      );
                    },
                  ),
                ),
    );
  }
}

class _RedditTrendingBlock extends ConsumerWidget {
  const _RedditTrendingBlock({required this.onTapPost});

  final void Function(String postId) onTapPost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(redditTrendingProvider);
    return async.when(
      data: (posts) {
        if (posts.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.trendingCatsFromReddit,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: posts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final post = posts[i];
                  return SizedBox(
                    width: 200,
                    child: Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.35)),
                      ),
                      child: InkWell(
                        onTap: () => onTapPost(post.postId),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                post.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.l10n.sourceReddit,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _FeedLoadingSkeleton extends StatelessWidget {
  const _FeedLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 6),
      children: const [
        SizedBox(height: 4),
        PostCardSkeleton(),
        PostCardSkeleton(),
        PostCardSkeleton(),
      ],
    );
  }
}
