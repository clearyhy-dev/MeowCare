import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/l10n_ext.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app/app_button.dart';
import '../../widgets/app/app_empty_state.dart';
import '../../widgets/app/error_state_view.dart';
import '../../widgets/app/skeleton_shimmer.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  static String _formatTime(DateTime? t) {
    if (t == null) return '';
    return DateFormat.yMMMd().add_Hm().format(t.toLocal());
  }

  Future<void> _openNotification(NotificationModel n) async {
    final postId = n.targetPostId.trim();
    if (postId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.postNotFound)),
        );
      }
      return;
    }

    final repo = ref.read(notificationRepositoryProvider);
    if (!n.isRead) {
      try {
        await repo.markNotificationRead(n.notificationId);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.notificationMarkReadFailed)),
          );
        }
        // 仍跳转帖子，避免用户无法查看内容
      }
    }
    if (!mounted) return;

    final isComment = n.type == 'reply_to_comment' || n.type == 'comment_on_post';
    final cid = (n.targetCommentId ?? '').trim();
    final qp = <String, String>{};
    if (isComment) {
      qp['focusComment'] = '1';
      if (cid.isNotEmpty) qp['commentId'] = cid;
    }
    final q = qp.isEmpty ? '' : '?${Uri(queryParameters: qp).query}';
    context.push('${AppRouter.home}post/$postId$q');
  }

  Future<void> _markAll() async {
    try {
      await ref.read(notificationRepositoryProvider).markAllNotificationsRead();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.notificationsAllMarkedRead)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.notificationMarkReadFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserAsyncProvider).valueOrNull;
    final uid = user?.uid ?? '';
    final asyncList = ref.watch(notificationsListStreamProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.notificationsTitle),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: AppButton(
                label: context.l10n.markAllNotificationsRead,
                variant: AppButtonVariant.ghost,
                onPressed: _markAll,
              ),
            ),
        ],
      ),
      body: user == null
          ? AppEmptyState(message: context.l10n.signInForFullFeatures, icon: Icons.lock_outline_rounded)
          : asyncList.when(
              loading: () => ShimmerScope(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: 7,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, __) => const SkeletonNotificationTile(),
                    ),
                  ),
              error: (_, __) => ErrorStateView(
                    title: context.l10n.notificationsLoadFailed,
                    onRetry: () => ref.invalidate(notificationsListStreamProvider(uid)),
                    retryLabel: context.l10n.retry,
                  ),
              data: (items) {
                if (items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(notificationsListStreamProvider(uid));
                      await ref.read(notificationsListStreamProvider(uid).future);
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.35,
                          child: AppEmptyState(
                            message: context.l10n.notificationsEmpty,
                            icon: Icons.notifications_none,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final scheme = Theme.of(context).colorScheme;
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(notificationsListStreamProvider(uid));
                    await ref.read(notificationsListStreamProvider(uid).future);
                  },
                  child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final n = items[i];
                    return Material(
                      color: scheme.surfaceContainerLow.withValues(alpha: n.isRead ? 0.65 : 0.95),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        onTap: () => _openNotification(n),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!n.isRead)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6, right: 10),
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: scheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              else
                                const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n.title.isNotEmpty ? n.title : n.type,
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    if (n.body.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        n.body,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatTime(n.createdAt),
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: scheme.outline,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                );
              },
            ),
    );
  }
}
