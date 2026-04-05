import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/i18n/app_language_display.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/meow_share.dart';
import '../../providers/ads_visibility_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/ads/meow_native_ad.dart';
import '../../widgets/app/app_button.dart';
import '../../widgets/app/app_empty_state.dart';
import '../../widgets/settings/app_language_sheet.dart';
import '../../widgets/settings/community_hub_section.dart';
import '../../widgets/settings/settings_section_header.dart';
import '../../widgets/settings/settings_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserAsyncProvider);
    final familyAsync = ref.watch(currentFamilyProvider);
    final statusAsync = ref.watch(subscriptionStatusProvider);
    final showAds = ref.watch(shouldShowAdsProvider);
    final user = userAsync.valueOrNull;
    final family = familyAsync.valueOrNull;
    final isOwner = family?.ownerUid == user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settings),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: user == null
          ? _buildNotSignedIn(context, ref)
          : ListView(
              padding: const EdgeInsets.only(bottom: 28),
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppInsets.screenPadding),
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainerLow.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md + 2,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage:
                                user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                            child: user.photoUrl.isEmpty ? const Icon(Icons.person_rounded) : null,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName.isNotEmpty ? user.displayName : context.l10n.me,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.email,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          AppIconButton(
                            icon: Icons.logout_rounded,
                            tooltip: context.l10n.signOut,
                            onPressed: () => _signOut(context, ref),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                const CommunityHubSection(),
                SizedBox(height: AppSpacing.xl),
                Divider(
                  height: 1,
                  indent: AppInsets.screenPadding,
                  endIndent: AppInsets.screenPadding,
                ),
                SizedBox(height: AppSpacing.md),
                SettingsSectionHeader(
                  title: context.l10n.settingsSectionShare,
                  padding: EdgeInsets.fromLTRB(
                    AppInsets.screenPadding,
                    AppSpacing.sm,
                    AppInsets.screenPadding,
                    AppSpacing.xs,
                  ),
                ),
                SettingsTile(
                  leading: Icon(Icons.ios_share_rounded, color: Theme.of(context).colorScheme.primary),
                  title: context.l10n.shareAppMenu,
                  onTap: () => MeowShare.shareApp(context),
                ),
                SizedBox(height: AppSpacing.sm),
                SettingsTile(
                  leading: Icon(Icons.workspace_premium_outlined,
                      color: Theme.of(context).colorScheme.primary),
                  title: context.l10n.subscription,
                  subtitle: statusAsync.valueOrNull == SubscriptionStatus.pro
                      ? context.l10n.pro
                      : context.l10n.free,
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.45)),
                  onTap: () => context.push('${AppRouter.home}subscription'),
                ),
                SizedBox(height: AppSpacing.lg),
                SettingsSectionHeader(
                  title: context.l10n.family,
                  padding: EdgeInsets.fromLTRB(
                    AppInsets.screenPadding,
                    AppSpacing.sm,
                    AppInsets.screenPadding,
                    AppSpacing.xs,
                  ),
                ),
                if (family != null) ...[
                  SettingsTile(
                    title: context.l10n.inviteCode,
                    subtitleWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.inviteCodeHint),
                        const SizedBox(height: 6),
                        SelectableText(
                          family.inviteCode,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () => _copyInviteCode(context, family.inviteCode),
                    ),
                  ),
                  FutureBuilder<int>(
                    future: ref.read(familyServiceProvider).getMemberCount(family.familyId),
                    builder: (context, snap) => SettingsTile(
                      title: context.l10n.members,
                      subtitle: '${snap.data ?? 0}',
                    ),
                  ),
                  if (isOwner)
                    SettingsTile(
                      title: context.l10n.manageMembers,
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.45)),
                      onTap: () => _showMembersInfo(context, ref, family.familyId),
                    )
                  else
                    SettingsTile(
                      title: context.l10n.leaveFamily,
                      titleColor: Theme.of(context).colorScheme.error,
                      onTap: () => _leaveFamily(context, ref, family.familyId, user.uid),
                    ),
                ],
                SizedBox(height: AppSpacing.lg),
                Divider(
                  height: 1,
                  indent: AppInsets.screenPadding,
                  endIndent: AppInsets.screenPadding,
                ),
                SettingsSectionHeader(
                  title: context.l10n.appLanguage,
                  subtitle: ref.watch(appLocaleProvider).valueOrNull == null
                      ? '${context.l10n.languageFollowSystem} · ${AppLanguageDisplay.fullName(ref.watch(effectiveUILanguageCodeProvider), context.l10n)}'
                      : AppLanguageDisplay.fullName(
                          ref.watch(appLocaleProvider).valueOrNull!.languageCode, context.l10n),
                  padding: EdgeInsets.fromLTRB(
                    AppInsets.screenPadding,
                    AppSpacing.lg,
                    AppInsets.screenPadding,
                    AppSpacing.xs,
                  ),
                ),
                SettingsTile(
                  leading: Icon(Icons.language_rounded, color: Theme.of(context).colorScheme.primary),
                  title: context.l10n.appLanguage,
                  subtitle: ref.watch(appLocaleProvider).valueOrNull == null
                      ? '${context.l10n.languageFollowSystem} · ${AppLanguageDisplay.fullName(ref.watch(effectiveUILanguageCodeProvider), context.l10n)}'
                      : AppLanguageDisplay.fullName(
                          ref.watch(appLocaleProvider).valueOrNull!.languageCode, context.l10n),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.45)),
                  onTap: () => showAppLanguageSheet(context, ref),
                ),
                if (showAds) ...[
                  SizedBox(height: AppSpacing.xl),
                  MeowNativeAdTile(show: showAds),
                ],
              ],
            ),
    );
  }

  Widget _buildNotSignedIn(BuildContext context, WidgetRef ref) {
    final showAds = ref.watch(shouldShowAdsProvider);
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: AppInsets.screenPadding, vertical: AppSpacing.lg),
      children: [
        AppEmptyState(
          message: context.l10n.signInForFullFeatures,
          icon: Icons.lock_outline_rounded,
          action: AppButton(
            label: context.l10n.signInWithGoogle,
            variant: AppButtonVariant.primary,
            icon: const Icon(Icons.account_circle_outlined, size: 22),
            onPressed: () => context.push(AppRouter.auth),
          ),
        ),
        SizedBox(height: AppSpacing.xxl),
        Divider(height: 1),
        SizedBox(height: AppSpacing.md),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppInsets.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsSectionHeader(
                title: context.l10n.appLanguage,
                subtitle: ref.watch(appLocaleProvider).valueOrNull == null
                    ? '${context.l10n.languageFollowSystem} · ${AppLanguageDisplay.fullName(ref.watch(effectiveUILanguageCodeProvider), context.l10n)}'
                    : AppLanguageDisplay.fullName(
                        ref.watch(appLocaleProvider).valueOrNull!.languageCode, context.l10n),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              SettingsTile(
                useScreenHorizontalPadding: false,
                leading: Icon(Icons.language_rounded, color: Theme.of(context).colorScheme.primary),
                title: context.l10n.appLanguage,
                subtitle: ref.watch(appLocaleProvider).valueOrNull == null
                    ? '${context.l10n.languageFollowSystem} · ${AppLanguageDisplay.fullName(ref.watch(effectiveUILanguageCodeProvider), context.l10n)}'
                    : AppLanguageDisplay.fullName(
                        ref.watch(appLocaleProvider).valueOrNull!.languageCode, context.l10n),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.45)),
                onTap: () => showAppLanguageSheet(context, ref),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md),
        Center(
          child: AppButton(
            label: context.l10n.shareAppMenu,
            variant: AppButtonVariant.ghost,
            icon: const Icon(Icons.ios_share_rounded, size: 20),
            onPressed: () => MeowShare.shareApp(context),
          ),
        ),
        if (showAds) ...[
          SizedBox(height: AppSpacing.xl),
          MeowNativeAdTile(show: showAds),
        ],
      ],
    );
  }

  void _copyInviteCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.inviteCodeCopied)));
  }

  void _showMembersInfo(BuildContext context, WidgetRef ref, String familyId) {
    ref.read(familyMembersProvider(familyId).future).then((members) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.familyMembers),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: members
                  .map(
                    (row) => ListTile(
                      title: Text(row.displayName),
                      subtitle: Text(
                        row.member.isOwner ? context.l10n.familyRoleOwner : context.l10n.familyRoleMember,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.ok)),
          ],
        ),
      );
    });
  }

  Future<void> _leaveFamily(BuildContext context, WidgetRef ref, String familyId, String? uid) async {
    if (uid == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.l10n.leaveFamilyConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(c).colorScheme.error),
            child: Text(context.l10n.leave),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(familyServiceProvider).leaveFamily(familyId, uid);
      ref.invalidate(currentUserAsyncProvider);
      ref.invalidate(currentFamilyProvider);
      if (context.mounted) context.go(AppRouter.createFamily);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authServiceProvider).signOut();
    ref.invalidate(authStateProvider);
    ref.invalidate(currentUserAsyncProvider);
    if (context.mounted) context.go(AppRouter.auth);
  }
}
