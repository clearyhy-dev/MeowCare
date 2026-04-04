import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_language_display.dart';
import '../../core/utils/l10n_ext.dart';
import '../../providers/locale_provider.dart';

/// Reddit 风底部表：选择「跟随系统」或固定语言。
Future<void> showAppLanguageSheet(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final manual = ref.read(appLocaleProvider).valueOrNull;
  final resolvedCode = ref.read(effectiveUILanguageCodeProvider);

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
    ),
    builder: (ctx) {
      final maxH = MediaQuery.sizeOf(ctx).height * 0.88;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  l10n.chooseAppLanguage,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              _LanguageTile(
                title: l10n.languageFollowSystem,
                subtitle: AppLanguageDisplay.fullName(resolvedCode, l10n),
                selected: manual == null,
                onTap: () async {
                  await ref.read(appLocaleProvider.notifier).setLanguageCode(null);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              const Divider(height: 1),
              ...kSupportedAppLanguageCodes.map((code) {
                return _LanguageTile(
                  title: AppLanguageDisplay.fullName(code, l10n),
                  subtitle: AppLanguageDisplay.chipLabel(code, l10n),
                  selected: manual?.languageCode == code,
                  onTap: () async {
                    await ref.read(appLocaleProvider.notifier).setLanguageCode(code);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
      ),
      trailing: selected ? Icon(Icons.check_circle, color: scheme.primary, size: 22) : null,
      onTap: onTap,
    );
  }
}
