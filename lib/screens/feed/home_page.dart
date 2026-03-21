import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/meow_share.dart';
import '../../core/i18n/app_language_display.dart';
import '../../core/utils/topic_l10n.dart';
import '../../models/post_model.dart';
import '../../providers/breed_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/like_provider.dart';
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
    final locale = ref.watch(effectiveUILanguageCodeProvider);
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
              : (!feedState.loading && feedState.posts.isEmpty)
                  ? Center(
                      child: Text(
                        context.l10n.feedNoContent,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
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
                      final postId = post.postId;
                      return _PostCard(
                        post: post,
                        onOpenPost: () => context.push('${AppRouter.postDetail}/$postId'),
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

/// Reddit 风格紧凑 Feed 卡片：信息优先、小图、轻分割；支持点赞、评论跳转、分享、收藏。
class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post, required this.onOpenPost});

  final PostModel post;
  final VoidCallback onOpenPost;

  static const double _imageHeight = 148;
  static const double _imageRadius = 11;

  static String _formatTime(DateTime? t) {
    if (t == null) return '';
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat.MMMd().format(t);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onSurfaceVariant = scheme.onSurfaceVariant;
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      height: 1.22,
      fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) + 1,
    );
    final langText = AppLanguageDisplay.chipLabel(post.language, context.l10n);
    final timeText = _formatTime(post.createdAt);
    final hasCategory = post.topics.isNotEmpty;
    final categoryText = hasCategory ? feedTopicCategoryLabel(context, post.topics.first) : '';
    final likedAsync = ref.watch(isLikedProvider(post.postId));
    final isLiked = likedAsync.valueOrNull == true;

    return Material(
      color: scheme.surface,
      child: InkWell(
        onTap: onOpenPost,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 8, 6, 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _FeedChip(text: langText),
                  if (hasCategory) ...[
                    const SizedBox(width: 6),
                    _FeedChip(text: categoryText),
                  ],
                  const Spacer(),
                  if (timeText.isNotEmpty)
                    Text(
                      timeText,
                      style: theme.textTheme.labelSmall?.copyWith(color: onSurfaceVariant, fontSize: 11.5),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(post.title, style: titleStyle),
              if (post.shouldShowImage) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(_imageRadius),
                  child: SizedBox(
                    height: _imageHeight,
                    width: double.infinity,
                    child: Image.network(
                      post.displayImageUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        final total = progress.expectedTotalBytes;
                        return ColoredBox(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: total != null && total > 0 ? progress.cumulativeBytesLoaded / total : null,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => ColoredBox(
                        color: scheme.surfaceContainerHighest,
                        child: Center(child: Icon(Icons.broken_image_outlined, size: 28, color: onSurfaceVariant)),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Row(
                children: [
                  _PostActionIcon(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    label: '${post.likeCount}',
                    color: isLiked ? scheme.primary : onSurfaceVariant,
                    tooltip: context.l10n.likes,
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final l10n = context.l10n;
                      final user = ref.read(currentUserAsyncProvider).valueOrNull;
                      if (user == null) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(l10n.signInForFullFeatures)),
                        );
                        return;
                      }
                      try {
                        await toggleLike(ref, post.postId);
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
                        );
                      }
                    },
                  ),
                  _PostActionIcon(
                    icon: Icons.chat_bubble_outline,
                    label: '${post.commentCount}',
                    color: onSurfaceVariant,
                    tooltip: context.l10n.comments,
                    onPressed: onOpenPost,
                  ),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    tooltip: context.l10n.share,
                    icon: Icon(Icons.share_outlined, size: 19, color: onSurfaceVariant),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      MeowShare.sharePost(
                        context,
                        postId: post.postId,
                        title: post.title,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostActionIcon extends StatelessWidget {
  const _PostActionIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedChip extends StatelessWidget {
  const _FeedChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.2,
              color: scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
