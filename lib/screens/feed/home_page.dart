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
import '../../widgets/post/post_card.dart';
import '../../widgets/post/post_card_skeleton.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedTopic;
  static const _topics = ['care', 'health', 'feeding', 'behavior'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final country = ref.read(appCountryProvider).valueOrNull;
      ref.read(feedProvider.notifier).loadFirst(orderByCreated: true, countryCode: country);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    final country = ref.read(appCountryProvider).valueOrNull;
    ref.read(feedProvider.notifier).loadFirst(
      orderByCreated: _tabController.index == 0,
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
        orderByCreated: _tabController.index == 0,
        topic: _selectedTopic,
        countryCode: nextCountry,
      );
    });

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
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                onTap: (i) {
                  AppFeedback.selection();
                  final country = ref.read(appCountryProvider).valueOrNull;
                  ref.read(feedProvider.notifier).loadFirst(
                    orderByCreated: i == 0,
                    topic: _selectedTopic,
                    countryCode: country,
                  );
                },
                tabs: [
                  Tab(text: context.l10n.latest),
                  Tab(text: context.l10n.hot),
                ],
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    _FilterChip(
                      label: context.l10n.topics,
                      allLabel: context.l10n.allTopics,
                      value: _selectedTopic,
                      options: _topics.map((t) => MapEntry(t, topicLabel(context, t))).toList(),
                      onSelected: (id) {
                        AppFeedback.selection();
                        setState(() {
                          _selectedTopic = id;
                        });
                        _onFilterChanged();
                      },
                    ),
                  ],
                ),
              ),
            ],
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
                        orderByCreated: _tabController.index == 0,
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
              : (!feedState.loading && feedState.posts.isEmpty)
                  ? AppEmptyState(message: context.l10n.feedNoContent, icon: Icons.forum_outlined)
                  : RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(redditTrendingProvider);
                    final country = ref.read(appCountryProvider).valueOrNull;
                    await ref.read(feedProvider.notifier).loadFirst(
                      orderByCreated: _tabController.index == 0,
                      topic: _selectedTopic,
                      countryCode: country,
                    );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                    itemCount: 1 + feedState.posts.length + (feedState.hasMore ? 1 : 0),
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
                      final postCount = feedState.posts.length;
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
                      final post = feedState.posts[postIndex];
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.allLabel,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final String allLabel;
  final String? value;
  final List<MapEntry<String, String>> options;
  final void Function(String?) onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final matches = options.where((e) => e.key == value).toList();
    final displayText = value == null ? label : (matches.isEmpty ? (value ?? label) : matches.first.value);

    return PopupMenuButton<String?>(
      onSelected: onSelected,
      tooltip: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value == null ? scheme.surfaceContainerLow : scheme.primaryContainer.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.tune_rounded, size: 16, color: value == null ? scheme.onSurfaceVariant : scheme.primary),
            const SizedBox(width: 6),
            Text(
              displayText,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: value == null ? scheme.onSurface : scheme.primary,
                  ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: null,
          child: Row(
            children: [
              if (value == null) Icon(Icons.check_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
              if (value == null) const SizedBox(width: 6),
              Text(allLabel),
            ],
          ),
        ),
        ...options.map((e) => PopupMenuItem(value: e.key, child: Text(e.value))),
      ],
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
