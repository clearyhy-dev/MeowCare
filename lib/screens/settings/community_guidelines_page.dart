import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/community_links.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n_ext.dart';
import '../../widgets/app/app_button.dart';

class CommunityGuidelinesPage extends StatelessWidget {
  const CommunityGuidelinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Future<void> openLink() async {
      final u = CommunityLinks.guidelinesUrl;
      if (u.isEmpty) return;
      final uri = Uri.tryParse(u);
      if (uri == null) return;
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.feedLoadFailed)),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.communityGuidelinesTitle),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppInsets.screenPadding,
          AppSpacing.lg,
          AppInsets.screenPadding,
          AppSpacing.xxl,
        ),
        children: [
          Text(
            l10n.communityGuidelinesLead,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          SizedBox(height: AppSpacing.xxl),
          _Para(text: l10n.communityGuidelinesP1, scheme: scheme, textTheme: textTheme),
          SizedBox(height: AppSpacing.lg),
          _Para(text: l10n.communityGuidelinesP2, scheme: scheme, textTheme: textTheme),
          SizedBox(height: AppSpacing.lg),
          _Para(text: l10n.communityGuidelinesP3, scheme: scheme, textTheme: textTheme),
          if (CommunityLinks.guidelinesUrl.isNotEmpty) ...[
            SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: l10n.communityHubGuidelinesSubtitle,
              variant: AppButtonVariant.secondary,
              onPressed: openLink,
            ),
          ],
        ],
      ),
    );
  }
}

class _Para extends StatelessWidget {
  const _Para({
    required this.text,
    required this.scheme,
    required this.textTheme,
  });

  final String text;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: textTheme.bodyLarge?.copyWith(
        color: scheme.onSurfaceVariant,
        height: 1.45,
      ),
    );
  }
}
