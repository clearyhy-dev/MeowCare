import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/app_language_display.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n_ext.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/app/app_button.dart';
import '../../widgets/settings/app_language_sheet.dart';
import '../../widgets/settings/settings_section_header.dart';

class CommunityPreferencesPage extends ConsumerWidget {
  const CommunityPreferencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final code = ref.watch(appLocaleProvider).valueOrNull?.languageCode;
    final effective = ref.watch(effectiveUILanguageCodeProvider);
    final langLine = code == null
        ? '${l10n.languageFollowSystem} · ${AppLanguageDisplay.fullName(effective, l10n)}'
        : AppLanguageDisplay.fullName(code, l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.communityPreferencesTitle),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: AppInsets.sectionSpacing),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppInsets.screenPadding,
              AppSpacing.md,
              AppInsets.screenPadding,
              AppSpacing.lg,
            ),
            child: Text(
              l10n.communityPreferencesSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppInsets.screenPadding),
            child: Text(
              l10n.communityComingSoon,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          SizedBox(height: AppSpacing.xxl),
          SettingsSectionHeader(
            title: l10n.appLanguage,
            subtitle: langLine,
            padding: EdgeInsets.fromLTRB(
              AppInsets.screenPadding,
              AppSpacing.lg,
              AppInsets.screenPadding,
              AppSpacing.sm,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppInsets.screenPadding),
            child: AppButton(
              label: l10n.appLanguage,
              variant: AppButtonVariant.secondary,
              icon: const Icon(Icons.language_outlined, size: 20),
              onPressed: () => showAppLanguageSheet(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}
