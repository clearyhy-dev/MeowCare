import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/meow_share.dart';
import '../../providers/family_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/user_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserAsyncProvider);
    final familyAsync = ref.watch(currentFamilyProvider);
    final statusAsync = ref.watch(subscriptionStatusProvider);
    final user = userAsync.valueOrNull;
    final family = familyAsync.valueOrNull;
    final isOwner = family?.ownerUid == user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settings),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: user == null
          ? SettingsScreen._buildNotSignedIn(context)
          : ListView(
              children: [
                const SizedBox(height: 16),
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                    child: user.photoUrl.isEmpty ? const Icon(Icons.person) : null,
                  ),
                  title: Text(user.displayName.isNotEmpty ? user.displayName : context.l10n.me),
                  subtitle: Text(user.email),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.workspace_premium),
                  title: Text(context.l10n.subscription),
                  subtitle: Text(statusAsync.valueOrNull == SubscriptionStatus.pro ? context.l10n.pro : context.l10n.free),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('${AppRouter.home}subscription'),
                ),
                const Divider(),
                Padding(
                  padding: EdgeInsets.fromLTRB(AppInsets.screenPadding, AppInsets.sectionSpacing / 2, AppInsets.screenPadding, 8),
                  child: Text(context.l10n.family, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                ),
                if (family != null) ...[
                  ListTile(
                    title: Text(context.l10n.inviteCode),
                    subtitle: SelectableText(family.inviteCode),
                    trailing: IconButton(icon: const Icon(Icons.copy), onPressed: () => _copyInviteCode(context, family.inviteCode)),
                  ),
                  FutureBuilder<int>(
                    future: ref.read(familyServiceProvider).getMemberCount(family.familyId),
                    builder: (context, snap) => ListTile(
                      title: Text(context.l10n.members),
                      subtitle: Text('${snap.data ?? 0}'),
                    ),
                  ),
                  if (isOwner)
                    ListTile(
                      title: Text(context.l10n.manageMembers),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showMembersInfo(context, ref, family.familyId),
                    )
                  else
                    ListTile(
                      title: Text(context.l10n.leaveFamily, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      onTap: () => _leaveFamily(context, ref, family.familyId, user.uid),
                    ),
                ],
                const Divider(),
                ListTile(
                  leading: Icon(Icons.ios_share_outlined, color: Theme.of(context).colorScheme.primary),
                  title: Text(context.l10n.shareAppMenu),
                  onTap: () => MeowShare.shareApp(context),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(context.l10n.signOut),
                  onTap: () => _signOut(context, ref),
                ),
              ],
            ),
    );
  }

  static Widget _buildNotSignedIn(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.signInForFullFeatures, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),

            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.account_circle_outlined),
              label: Text(context.l10n.signInWithGoogle),
              onPressed: () => context.push(AppRouter.auth),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.ios_share_outlined, size: 20),
              label: Text(context.l10n.shareAppMenu),
              onPressed: () => MeowShare.shareApp(context),
            ),
          ],
        ),
      ),
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
              children: members.map((m) => ListTile(title: Text(m.uid), subtitle: Text(m.role.value))).toList(),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.ok))],
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
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(context.l10n.leave)),

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

