import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_feedback.dart';
import '../../core/utils/l10n_ext.dart';
import '../../models/post_model.dart';
import '../../providers/ads_visibility_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/ads/meow_native_ad.dart';
import '../../widgets/app/empty_state_view.dart';
import '../../widgets/app/error_state_view.dart';
import '../../widgets/app/feed_loading_placeholder.dart';
import '../../widgets/feed/feed_control_bar.dart';
import '../../widgets/feed/reddit_recommendation_section.dart';
import '../../widgets/post/post_card.dart';

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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(context.l10n.feed),
        actions: [
          if (user != null)
            IconButton(
              tooltip: context.l10n.myCats,
              icon: const Icon(Icons.pets_rounded),
              onPressed: () => context.push('${AppRouter.home}my-cats'),
            ),
          IconButton(
            tooltip: context.l10n.profile,
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
          preferredSize: const Size.fromHeight(132),
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
          ? ErrorStateView(
              title: context.l10n.feedLoadFailed,
              retryLabel: context.l10n.retry,
              onRetry: () {
                final country = ref.read(appCountryProvider).valueOrNull;
                final lang = ref.read(effectiveUILanguageCodeProvider);
                ref.read(feedProvider.notifier).loadFirst(
                  orderByCreated: _latestSelected,
                  countryCode: country,
                  languageCode: lang,
                );
              },
            )
          : feedState.loading && feedState.posts.isEmpty
              ? ListView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  children: const [
                    FeedLoadingPlaceholder(count: 4),
                  ],
                )
              : (!feedState.loading && posts.isEmpty)
                  ? EmptyStateView(
                      message: context.l10n.feedNoContent,
                      icon: Icons.forum_outlined,
                      useScrollView: true,
                    )
                  : (!feedState.loading && posts.isNotEmpty && visiblePosts.isEmpty)
                      ? EmptyStateView(
                          message: context.l10n.noResultFound,
                          icon: Icons.search_off_rounded,
                          useScrollView: true,
                        )
                      : RefreshIndicator(
                  onRefresh: () async {
                    AppFeedback.selection();
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
                        return RedditRecommendationSection(
                          onTapPost: (postId) => context.push('${AppRouter.postDetail}/$postId'),
                        );
                      }
                      final rowIndex = index - 1;
                      final rowCount = feedRows.length;
                      if (rowIndex >= rowCount) {
                        if (rowIndex == rowCount) {
                          ref.read(feedProvider.notifier).loadMore();
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.lg,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  context.l10n.feedLoadingMore,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
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
