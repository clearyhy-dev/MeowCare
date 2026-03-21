import 'package:flutter/material.dart';

import '../core/utils/l10n_ext.dart';

/// Shown when free user hits limit (e.g. second cat or second member).
void showUpgradeDialog(BuildContext context, {VoidCallback? onSeePro}) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.pets, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(context.l10n.upgradeForFamilySharing)),
        ],
      ),
      content: Text(context.l10n.upgradeForFamilySharingBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onSeePro?.call();
          },
          child: Text(context.l10n.goToSubscription),
        ),
      ],
    ),
  );
}
