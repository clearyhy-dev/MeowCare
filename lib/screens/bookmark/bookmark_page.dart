import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/utils/l10n_ext.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/user_provider.dart';

class BookmarkPage extends ConsumerWidget {
  const BookmarkPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserAsyncProvider).valueOrNull;
    final bookmarksAsync = ref.watch(bookmarkedPostsProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.bookmarks)),
        body: Center(child: Text(context.l10n.signInToSeeBookmarks)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.bookmarks)),
      body: bookmarksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.errorWithMessage(e.toString()))),
        data: (result) {
          if (result.list.isEmpty) {
            return Center(child: Text(context.l10n.noBookmarksYet));
          }
          return ListView.builder(
            itemCount: result.list.length,
            itemBuilder: (context, index) {
              final post = result.list[index];
              return ListTile(
                title: Text(post.title),
                subtitle: Text(post.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () => context.push('${AppRouter.home}post/${post.postId}'),
              );
            },
          );
        },
      ),
    );
  }
}
