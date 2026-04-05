import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n_ext.dart';
import '../../providers/notification_provider.dart';
import '../app/app_button.dart';
import 'app_language_sheet.dart';
import 'settings_badge.dart';
import 'settings_grid_card.dart';
import 'settings_section_header.dart';

class CommunityHubSection extends ConsumerWidget {
  const CommunityHubSection({
    super.key,
    this.showSectionHeader = true,
    this.wrapWithScreenPadding = true,
    this.showLanguageTile = true,
  });

  /// When placed inside a [SettingsGroupCard], set to false to avoid duplicate titles.
  final bool showSectionHeader;

  /// Outer horizontal padding; set false when parent already applies screen inset.
  final bool wrapWithScreenPadding;

  /// Set false when language is shown in a separate settings group.
  final bool showLanguageTile;

  static void showBlockedSheet(BuildContext context) {
    final l = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.communityBlockedTitle,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  l.communityBlockedBody,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: l.ok,
                  variant: AppButtonVariant.primary,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final h = AppRouter.home;
    final unreadAsync = ref.watch(notificationUnreadCountProvider);

    final notifTrailing = unreadAsync.when(
      data: (n) => n > 0 ? SettingsBadge(count: n) : null,
      loading: () => const _BadgePlaceholder(),
      error: (_, __) => null,
    );

    final grid = GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.36,
            children: [
              SettingsGridCard(
                icon: Icons.article_outlined,
                title: l.myPostsTitle,
                subtitle: l.communityHubPostsSubtitle,
                onTap: () => context.push('${h}me/posts'),
              ),
              SettingsGridCard(
                icon: Icons.chat_bubble_outline_rounded,
                title: l.myCommentsTitle,
                subtitle: l.communityHubCommentsSubtitle,
                onTap: () => context.push('${h}me/comments'),
              ),
              SettingsGridCard(
                icon: Icons.bookmark_border_rounded,
                title: l.savedPostsTitle,
                subtitle: l.communityHubSavedSubtitle,
                onTap: () => context.push('${h}me/saved'),
              ),
              SettingsGridCard(
                icon: Icons.notifications_outlined,
                title: l.notificationsTitle,
                subtitle: l.communityHubNotificationsSubtitle,
                trailing: notifTrailing,
                onTap: () => context.push('${h}me/notifications'),
              ),
              SettingsGridCard(
                icon: Icons.tune_rounded,
                title: l.communityPreferencesTitle,
                subtitle: l.communityHubPreferencesSubtitle,
                onTap: () => context.push('${h}me/community-preferences'),
              ),
              if (showLanguageTile)
                SettingsGridCard(
                  icon: Icons.language_rounded,
                  title: l.appLanguage,
                  subtitle: l.communityHubLanguageSubtitle,
                  onTap: () => showAppLanguageSheet(context, ref),
                ),
              SettingsGridCard(
                icon: Icons.visibility_off_outlined,
                title: l.communityBlockedTitle,
                subtitle: l.communityHubBlockedSubtitle,
                onTap: () => showBlockedSheet(context),
              ),
              SettingsGridCard(
                icon: Icons.menu_book_outlined,
                title: l.communityGuidelinesTitle,
                subtitle: l.communityHubGuidelinesSubtitle,
                onTap: () => context.push('${h}me/community-guidelines'),
              ),
            ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSectionHeader)
          SettingsSectionHeader(
            title: l.communityHubTitle,
            subtitle: l.communityHubSubtitle,
          ),
        Padding(
          padding: wrapWithScreenPadding
              ? EdgeInsets.symmetric(horizontal: AppInsets.screenPadding)
              : EdgeInsets.zero,
          child: grid,
        ),
      ],
    );
  }
}

class _BadgePlaceholder extends StatelessWidget {
  const _BadgePlaceholder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 22,
      height: 16,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
