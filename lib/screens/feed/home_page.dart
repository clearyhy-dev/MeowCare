import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/topic_l10n.dart';
import '../../models/post_model.dart';
import '../../providers/breed_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/user_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedTopic;
  String? _selectedBreedId;
  static const _topics = ['care', 'health', 'feeding', 'behavior'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final country = ref.read(appCountryProvider).valueOrNull;
      ref.read(feedProvider.notifier).loadFirst(orderByCreated: true, countryCode: country, breedId: _selectedBreedId);
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
      breedId: _selectedBreedId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final breedsAsync = ref.watch(breedsFutureProvider);
    final locale = Localizations.localeOf(context).languageCode;
    final user = ref.watch(currentUserAsyncProvider).valueOrNull;
    ref.listen<AsyncValue<String?>>(appCountryProvider, (prev, next) {
      if (!next.hasValue) return;
      final nextCountry = next.valueOrNull;
      if (prev?.valueOrNull == nextCountry) return;
      ref.read(feedProvider.notifier).loadFirst(
        orderByCreated: _tabController.index == 0,
        topic: _selectedTopic,
        countryCode: nextCountry,
        breedId: _selectedBreedId,
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.feed),
        actions: [
          if (user != null) IconButton(icon: const Icon(Icons.pets), onPressed: () => context.push('${AppRouter.home}my-cats')),
          if (user != null) IconButton(icon: const Icon(Icons.bookmark_border), onPressed: () => context.push('${AppRouter.home}bookmarks')),
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
                  final country = ref.read(appCountryProvider).valueOrNull;
                  ref.read(feedProvider.notifier).loadFirst(
                    orderByCreated: i == 0,
                    breedId: _selectedBreedId,
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
                      label: context.l10n.breeds,
                      allLabel: context.l10n.allBreeds,
                      value: _selectedBreedId,
                      options: breedsAsync.valueOrNull?.map((b) => MapEntry(b.breedId, b.displayName(locale))).toList() ?? [],

                      onSelected: (id) {
                        setState(() {
                          _selectedBreedId = id;
                          _selectedTopic = null;
                        });
                        _onFilterChanged();
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: context.l10n.topics,
                      allLabel: context.l10n.allTopics,
                      value: _selectedTopic,
                      options: _topics.map((t) => MapEntry(t, topicLabel(context, t))).toList(),
                      onSelected: (id) {
                        setState(() {
                          _selectedTopic = id;
                          _selectedBreedId = null;
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
                        breedId: _selectedBreedId,
                      );
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(context.l10n.retry),
                  ),
                ],
              ),
            )
          : feedState.loading && feedState.posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.loadingRegionContent,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(


              onRefresh: () async {
                ref.invalidate(redditTrendingProvider);
                final country = ref.read(appCountryProvider).valueOrNull;
                await ref.read(feedProvider.notifier).loadFirst(
                  orderByCreated: _tabController.index == 0,
                  topic: _selectedTopic,
                  countryCode: country,
                  breedId: _selectedBreedId,
                );
              },


              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: 1 + feedState.posts.length + (feedState.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
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
                  final postId = post.postId;
                  return _PostCard(
                    post: post,
                    onTap: () => context.push('${AppRouter.postDetail}/$postId'),
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
                      child: InkWell(
                        onTap: () => onTapPost(post.postId),
                        borderRadius: BorderRadius.circular(AppRadius.card),
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
            const SizedBox(height: 16),
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
    final matches = options.where((e) => e.key == value).toList();
    final displayText = value == null ? label : (matches.isEmpty ? (value ?? label) : matches.first.value);

    return PopupMenuButton<String?>(
      onSelected: onSelected,
      tooltip: label,
      child: Chip(
        avatar: const Icon(Icons.tune, size: 18),
        label: Text(displayText),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(value: null, child: Text(allLabel)),
        ...options.map((e) => PopupMenuItem(value: e.key, child: Text(e.value))),
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.onTap});

  final PostModel post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium ?? theme.textTheme.bodyLarge;
    final coverUrl = post.coverUrl;
    final title = post.title;
    final summary = post.summary;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (coverUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    coverUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      final total = progress.expectedTotalBytes;
                      return SizedBox(
                        height: 160,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: total != null && total > 0 ? progress.cumulativeBytesLoaded / total : null,
                          ),
                        ),
                      );
                    },


                    errorBuilder: (context, error, stackTrace) => SizedBox(height: 160, child: Center(child: Icon(Icons.broken_image, size: 48, color: theme.colorScheme.outline))),
                  ),
                )
              else
                const SizedBox(height: 8),
              const SizedBox(height: 8),
              Text(title, style: titleStyle),
              if (summary.isNotEmpty) ...[const SizedBox(height: 4), Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis)],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.favorite_border, size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text('${post.likeCount}'),
                  const SizedBox(width: 16),
                  Icon(Icons.chat_bubble_outline, size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text('${post.commentCount}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


