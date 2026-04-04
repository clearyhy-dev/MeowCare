import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/user_language_hint.dart';
import '../../models/symptom_advice_result.dart';
import '../../providers/cat_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/ai_service.dart';
import '../../widgets/app/app_button.dart';

class AIScreen extends ConsumerStatefulWidget {
  const AIScreen({super.key});

  @override
  ConsumerState<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends ConsumerState<AIScreen> {
  final _symptomController = TextEditingController();
  Severity _severity = Severity.green;
  bool _loading = false;
  SymptomAdviceResult? _result;

  String? _error;

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final symptom = _symptomController.text.trim();
    if (symptom.isEmpty) {
      setState(() => _error = context.l10n.aiErrorDescribeSymptom);
      return;
    }
    final appLanguage = ref.read(effectiveUILanguageCodeProvider);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final userHint = userLanguageHintFromText(symptom);
    final uid = ref.read(authServiceProvider).currentUid;

    if (uid == null) return;
    final status = await ref.read(subscriptionStatusProvider.future);
    final isPro = status == SubscriptionStatus.pro;
    final result = await ref.read(aiServiceProvider).checkCanRequestAI(uid, isPro);
    if (!result.canRequest) {
      setState(() => _error = context.l10n.aiErrorFreeLimit(AppConstants.freeAiRequestsPerDay));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final request = await ref.read(aiServiceProvider).submitRequest(uid, symptom, _severity);
      final advice = await ref.read(aiServiceProvider).getAIResponse(
            request.requestId,
            symptom,
            _severity,
            localeTag: localeTag,
            appLanguage: appLanguage,
            userLanguageHint: userHint,
          );
      if (mounted) setState(() { _loading = false; _result = advice; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(subscriptionStatusProvider);
    final catsAsync = ref.watch(currentFamilyCatsFutureProvider);
    final isPro = statusAsync.valueOrNull == SubscriptionStatus.pro;
    final cats = catsAsync.valueOrNull;
    final firstCatName = cats != null && cats.isNotEmpty ? cats.first.name : null;

    final aiTitle = firstCatName != null ? context.l10n.aiTitleWithName(firstCatName) : context.l10n.aiTitleGeneric;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.aiSymptomSupport),
        actions: [
          if (!isPro)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: AppButton(
                label: context.l10n.pro,
                variant: AppButtonVariant.small,
                onPressed: () => context.push('${AppRouter.home}subscription'),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.pets, color: scheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text(aiTitle, style: textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.aiSubtitle,
              style: textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _symptomController,
              decoration: InputDecoration(
                labelText: context.l10n.aiHint,
                border: const OutlineInputBorder(),
                hintText: context.l10n.aiHint,
              ),

              maxLines: 3,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 12),
            Text(context.l10n.severity, style: textTheme.labelLarge),
            Row(
              children: [
                Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(context.l10n.severityGreen), selected: _severity == Severity.green, onSelected: (_) => setState(() => _severity = Severity.green))),
                Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(context.l10n.severityYellow), selected: _severity == Severity.yellow, onSelected: (_) => setState(() => _severity = Severity.yellow))),
                Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(context.l10n.severityRed), selected: _severity == Severity.red, onSelected: (_) => setState(() => _severity = Severity.red))),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
            const SizedBox(height: 16),
            AppButton(
              label: context.l10n.getGuidance,
              variant: AppButtonVariant.primary,
              loading: _loading,
              onPressed: _submit,
            ),
            if (_result != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              Text(context.l10n.guidance, style: textTheme.titleMedium),
              const SizedBox(height: 12),
              _adviceSectionCard(context, context.l10n.aiAdviceSectionSummary, _result!.sections.summary),
              _adviceSectionCard(context, context.l10n.aiAdviceSectionHomeCare, _result!.sections.homeCare),
              _adviceSectionCard(
                context,
                context.l10n.aiAdviceSectionRedFlags,
                _result!.sections.riskWarnings,
                titleColor: scheme.error,
              ),
              _adviceSectionCard(context, context.l10n.aiAdviceSectionVet, _result!.sections.vetWhen),
              if (_result!.sections.reassurance.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _result!.sections.reassurance,
                  style: textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: scheme.primary,
                  ),
                ),
              ],
              _adviceSectionCard(context, context.l10n.aiAdviceSectionDisclaimer, _result!.sections.disclaimer),
              const SizedBox(height: 8),
              Text(
                '${context.l10n.aiModelLabel}: ${_result!.modelDisplayName}',
                style: textTheme.bodySmall?.copyWith(color: scheme.outline),
              ),
              if (kDebugMode &&
                  (_result!.detectedLanguage.isNotEmpty || _result!.responseLanguage.isNotEmpty)) ...[
                const SizedBox(height: 4),
                Text(
                  'detected=${_result!.detectedLanguage} · response=${_result!.responseLanguage}',
                  style: textTheme.bodySmall?.copyWith(color: scheme.outline, fontSize: 11),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                context.l10n.aiSubtitle,
                style: textTheme.bodySmall?.copyWith(color: scheme.outline),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _adviceSectionCard(
    BuildContext context,
    String title,
    String body, {
    Color? titleColor,
  }) {
    if (body.trim().isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(body, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

final aiServiceProvider = Provider<AIService>((ref) => AIService());
