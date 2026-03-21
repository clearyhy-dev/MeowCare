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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.free, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('• ${context.l10n.freeCats(AppConstants.freeMaxCats)}'),
                  Text('• ${context.l10n.freeMembers(AppConstants.freeMaxMembers)}'),
                  Text('• ${context.l10n.freeAiPerDay(AppConstants.freeAiRequestsPerDay)}'),
                  if (!isPro) Text('• ${context.l10n.currentPlan}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(context.l10n.pro, style: Theme.of(context).textTheme.titleMedium),
                      if (isPro) Padding(padding: const EdgeInsets.only(left: 8), child: Text(context.l10n.currentPlan, style: const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('• ${context.l10n.multipleCats}'),
                  Text('• ${context.l10n.multipleMembers}'),
                  Text('• ${context.l10n.unlimitedAi}'),
                  Text('• ${context.l10n.advancedReminders}'),
                  const SizedBox(height: 16),
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
          ),
        ],
      ),
    );
  }
}
