import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n_ext.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/user_provider.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(subscriptionStatusProvider);
    final userAsync = ref.watch(currentUserAsyncProvider);
    final uid = userAsync.valueOrNull?.uid;
    final isPro = statusAsync.valueOrNull == SubscriptionStatus.pro;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.subscription),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: AppInsets.screenPadding, vertical: AppInsets.sectionSpacing / 2),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.free, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text('• ${context.l10n.freeCats(AppConstants.freeMaxCats)}', style: Theme.of(context).textTheme.bodyLarge),
                Text('• ${context.l10n.freeMembers(AppConstants.freeMaxMembers)}', style: Theme.of(context).textTheme.bodyLarge),
                Text('• ${context.l10n.freeAiPerDay(AppConstants.freeAiRequestsPerDay)}', style: Theme.of(context).textTheme.bodyLarge),
                if (!isPro)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('• ${context.l10n.currentPlan}', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
          Divider(height: 24, thickness: 0.5, color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(context.l10n.pro, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    if (isPro)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(context.l10n.currentPlan, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('• ${context.l10n.multipleCats}', style: Theme.of(context).textTheme.bodyLarge),
                Text('• ${context.l10n.multipleMembers}', style: Theme.of(context).textTheme.bodyLarge),
                Text('• ${context.l10n.unlimitedAi}', style: Theme.of(context).textTheme.bodyLarge),
                Text('• ${context.l10n.advancedReminders}', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: isPro || uid == null
                      ? null
                      : () async {
                          await ref.read(subscriptionServiceProvider).setPro(uid);
                          ref.invalidate(subscriptionStatusProvider);
                          ref.invalidate(currentUserAsyncProvider);
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.proActivated)));
                        },
                  child: Text(isPro ? context.l10n.currentPlan : context.l10n.upgradeToPro),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
