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
import '../../widgets/app/settings_group_card.dart';
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(context.l10n.settings),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: user == null
          ? _buildNotSignedIn(context, ref)
          : ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              children: [
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppInsets.screenPadding),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.primaryContainer.withValues(alpha: 0.9),
                          scheme.surfaceContainerLow.withValues(alpha: 0.95),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundImage:
                                user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                            child: user.photoUrl.isEmpty ? const Icon(Icons.person_rounded, size: 32) : null,
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
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  user.email,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SettingsGroupCard(
                  title: context.l10n.settingsSectionAccount,
                  child: SettingsTile(
                    leading: Icon(Icons.workspace_premium_outlined, color: scheme.primary),
                    title: context.l10n.subscription,
                    subtitle: statusAsync.valueOrNull == SubscriptionStatus.pro
                        ? context.l10n.pro
                        : context.l10n.free,
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.45)),
                    onTap: () => context.push('${AppRouter.home}subscription'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SettingsGroupCard(
                  title: context.l10n.settingsSectionMyContent,
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: const CommunityHubSection(
                    showSectionHeader: false,
                    wrapWithScreenPadding: false,
                    showLanguageTile: false,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SettingsGroupCard(
                  title: context.l10n.settingsSectionNotifications,
                  child: SettingsTile(
                    leading: Icon(Icons.language_rounded, color: scheme.primary),
                    title: context.l10n.appLanguage,
                    subtitle: ref.watch(appLocaleProvider).valueOrNull == null
                        ? '${context.l10n.languageFollowSystem} · ${AppLanguageDisplay.fullName(ref.watch(effectiveUILanguageCodeProvider), context.l10n)}'
                        : AppLanguageDisplay.fullName(
                            ref.watch(appLocaleProvider).valueOrNull!.languageCode, context.l10n),
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.45)),
                    onTap: () => showAppLanguageSheet(context, ref),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SettingsGroupCard(
                  title: context.l10n.settingsSectionShare,
                  child: SettingsTile(
                    leading: Icon(Icons.ios_share_rounded, color: scheme.primary),
                    title: context.l10n.shareAppMenu,
                    onTap: () => MeowShare.shareApp(context),
                  ),
                ),
                if (family != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  SettingsGroupCard(
                    title: context.l10n.family,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                                color: scheme.onSurfaceVariant.withValues(alpha: 0.45)),
                            onTap: () => _showMembersInfo(context, ref, family.familyId),
                          )
                        else
                          SettingsTile(
                            title: context.l10n.leaveFamily,
                            titleColor: scheme.error,
                            onTap: () => _leaveFamily(context, ref, family.familyId, user.uid),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppInsets.screenPadding),
                  child: AppButton(
                    label: context.l10n.signOut,
                    variant: AppButtonVariant.danger,
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    onPressed: () => _signOut(context, ref),
                  ),
                ),
                if (showAds) ...[
                  const SizedBox(height: AppSpacing.xl),
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
