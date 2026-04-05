import 'package:flutter/material.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/l10n_ext.dart';
import '../../models/symptom_advice_result.dart';
import '../app/app_surface_card.dart';

/// 结构化症状分析展示（与后端 `/ai/symptom` 字段一致）。
class SymptomResultPanel extends StatelessWidget {
  const SymptomResultPanel({
    super.key,
    required this.result,
    required this.userSeverity,
  });

  final SymptomAdviceResult result;
  final Severity userSeverity;

  Color _severityColor(ColorScheme scheme, Severity s) {
    switch (s) {
      case Severity.red:
        return scheme.error;
      case Severity.yellow:
        return const Color(0xFFC49000);
      case Severity.green:
        return scheme.tertiary;
    }
  }

  String _severityLabel(BuildContext context, Severity s) {
    final l = context.l10n;
    switch (s) {
      case Severity.red:
        return l.severityRed;
      case Severity.yellow:
        return l.severityYellow;
      case Severity.green:
        return l.severityGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final a = result.analysis;
    final assessed = a.severity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (result.apiFallback) ...[
          AppSurfaceCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            showShadow: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: scheme.primary, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    context.l10n.aiFallbackBanner,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppSurfaceCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          showShadow: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.aiResultRiskNotice,
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.aiSubtitle,
                style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _SeverityChip(
              label: context.l10n.aiUserSeverity,
              value: _severityLabel(context, userSeverity),
              color: _severityColor(scheme, userSeverity),
            ),
            _SeverityChip(
              label: context.l10n.aiAssessedSeverity,
              value: _severityLabel(context, assessed),
              color: _severityColor(scheme, assessed),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (a.summary.isNotEmpty) _sectionCard(context, title: context.l10n.aiAdviceSectionSummary, body: a.summary),
        if (a.possibleCauses.isNotEmpty)
          _sectionCard(
            context,
            title: context.l10n.aiPossibleCauses,
            body: a.possibleCauses.map((e) => '• $e').join('\n'),
          ),
        if (a.watchAtHome.isNotEmpty)
          _sectionCard(context, title: context.l10n.aiWatchAtHome, body: a.watchAtHome),
        if (a.seekVetNow.isNotEmpty)
          _sectionCard(
            context,
            title: context.l10n.aiSeekVetUrgent,
            body: a.seekVetNow,
            titleColor: scheme.error,
          ),
        if (a.nextQuestions.isNotEmpty)
          _sectionCard(
            context,
            title: context.l10n.aiNextQuestions,
            body: a.nextQuestions.map((e) => '• $e').join('\n'),
          ),
        if (a.disclaimer.isNotEmpty)
          _sectionCard(
            context,
            title: context.l10n.aiAdviceSectionDisclaimer,
            body: a.disclaimer,
            titleColor: scheme.onSurfaceVariant,
          ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${context.l10n.aiModelLabel}: ${result.modelDisplayName}',
          style: textTheme.bodySmall?.copyWith(color: scheme.outline),
        ),
      ],
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required String body,
    Color? titleColor,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppSurfaceCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        showShadow: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: titleColor ?? scheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(body, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(
            value,
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
