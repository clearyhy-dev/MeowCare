import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/app_feedback.dart';
import '../../core/utils/l10n_ext.dart';
import '../../models/post_model.dart';
import '../../providers/ads_visibility_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/ads/meow_native_ad.dart';
import '../../widgets/app/app_empty_state.dart';
import '../../widgets/feed/feed_control_bar.dart';
import '../../widgets/post/post_card.dart';
import '../../widgets/post/post_card_skeleton.dart';

/// Feed 列表中的横幅占位（与 [PostModel] 区分）。
class _FeedAdSlot {
  const _FeedAdSlot();
}

List<Object> _feedRowsWithAds(List<PostModel> posts, bool showAds) {
  if (!showAds || posts.isEmpty) return List<Object>.from(posts);
  const interval = 5;
  final out = <Object>[];
  for (var i = 0; i < posts.length; i++) {
    out.add(posts[i]);
    if ((i + 1) % interval == 0) {
      out.add(const _FeedAdSlot());
    }
  }
  return out;
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  String _searchText = '';
  bool _latestSelected = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final country = ref.read(appCountryProvider).valueOrNull;
      final lang = ref.read(effectiveUILanguageCodeProvider);
      ref.read(feedProvider.notifier).loadFirst(
            orderByCreated: true,
            countryCode: country,
            languageCode: lang,
          );
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
    final lang = ref.read(effectiveUILanguageCodeProvider);
    ref.read(feedProvider.notifier).loadFirst(
      orderByCreated: _latestSelected,
      countryCode: country,
      languageCode: lang,
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final user = ref.watch(currentUserAsyncProvider).valueOrNull;
    final unreadAsync = ref.watch(notificationUnreadCountProvider);
    final unread = unreadAsync.valueOrNull ?? 0;
    ref.listen<AsyncValue<String?>>(appCountryProvider, (prev, next) {
      if (!next.hasValue) return;
      final nextCountry = next.valueOrNull;
      if (prev?.valueOrNull == nextCountry) return;
      final lang = ref.read(effectiveUILanguageCodeProvider);
      ref.read(feedProvider.notifier).loadFirst(
        orderByCreated: _latestSelected,
        countryCode: nextCountry,
        languageCode: lang,
      );
    });
    ref.listen<String>(effectiveUILanguageCodeProvider, (prev, next) {
      if (prev == next) return;
      final country = ref.read(appCountryProvider).valueOrNull;
      ref.read(feedProvider.notifier).loadFirst(
        orderByCreated: _latestSelected,
        countryCode: country,
        languageCode: next,
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

    final showAds = ref.watch(shouldShowAdsProvider);
    final feedRows = _feedRowsWithAds(visiblePosts, showAds);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.feed),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.pets_rounded),
              onPressed: () => context.push('${AppRouter.home}my-cats'),
            ),
          IconButton(
            onPressed: () => context.push('${AppRouter.home}settings'),
            icon: unread > 0
                ? Badge(
                    label: Text(unread > 99 ? '99+' : '$unread'),
                    child: const Icon(Icons.person_rounded),
                  )
                : const Icon(Icons.person_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(118),
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
                      final lang = ref.read(effectiveUILanguageCodeProvider);
                      ref.read(feedProvider.notifier).loadFirst(
                        orderByCreated: _latestSelected,
                        countryCode: country,
                        languageCode: lang,
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
                    final lang = ref.read(effectiveUILanguageCodeProvider);
                    await ref.read(feedProvider.notifier).loadFirst(
                      orderByCreated: _latestSelected,
                      countryCode: country,
                      languageCode: lang,
                    );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                    itemCount: 1 + feedRows.length + (feedState.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: _RedditTrendingBlock(
                            onTapPost: (postId) => context.push('${AppRouter.postDetail}/$postId'),
                          ),
                        );
                      }
                      final rowIndex = index - 1;
                      final rowCount = feedRows.length;
                      if (rowIndex >= rowCount) {
                        if (rowIndex == rowCount) {
                          ref.read(feedProvider.notifier).loadMore();
                        }
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (rowIndex < 0 || rowIndex >= rowCount) {
                        return const SizedBox.shrink();
                      }
                      final item = feedRows[rowIndex];
                      if (item is _FeedAdSlot) {
                        return MeowNativeAdTile(show: showAds);
                      }
                      final post = item as PostModel;
                      return PostCard(
                        post: post,
                        onOpenPost: () => context.push('${AppRouter.postDetail}/${post.postId}'),
                        onCommentTap: () => context.push('${AppRouter.postDetail}/${post.postId}?focusComment=1'),
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
                  final scheme = Theme.of(context).colorScheme;
                  return SizedBox(
                    width: 200,
                    child: Material(
                      color: scheme.surfaceContainerLow.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => onTapPost(post.postId),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                post.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                context.l10n.sourceReddit,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
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
