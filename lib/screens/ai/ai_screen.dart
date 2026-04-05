import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/user_language_hint.dart';
import '../../models/symptom_advice_result.dart';
import '../../providers/cat_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/ai_service.dart';
import '../../widgets/ads/rewarded_ad_helper.dart';
import '../../widgets/ai/symptom_result_panel.dart';
import '../../widgets/app/app_button.dart';
import '../../widgets/app/app_surface_card.dart';

class AIScreen extends ConsumerStatefulWidget {
  const AIScreen({super.key});

  @override
  ConsumerState<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends ConsumerState<AIScreen> {
  final _symptomController = TextEditingController();
  final _scrollController = ScrollController();
  Severity _severity = Severity.green;
  bool _loading = false;
  SymptomAdviceResult? _result;

  String? _error;
  AIServiceException? _serviceException;

  @override
  void dispose() {
    _symptomController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _messageForServiceError(BuildContext context, AIServiceException e) {
    switch (e.kind) {
      case AIServiceErrorKind.timeout:
        return context.l10n.aiTimeoutErrorShort;
      case AIServiceErrorKind.network:
        return context.l10n.aiNetworkErrorShort;
      case AIServiceErrorKind.unauthorized:
        return context.l10n.aiAuthErrorShort;
      case AIServiceErrorKind.httpError:
        return context.l10n.errorGenericRetry;
    }
  }

  Future<void> _submit() async {
    final symptom = _symptomController.text.trim();
    if (symptom.isEmpty) {
      setState(() {
        _error = context.l10n.aiErrorDescribeSymptom;
        _serviceException = null;
      });
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
      setState(() {
        _error = context.l10n.aiErrorFreeLimit(AppConstants.freeAiRequestsPerDay);
        _serviceException = null;
      });
      return;
    }
    final rewarded = await showRewardedForAiUse(ref);
    if (!mounted) return;
    if (!rewarded) {
      setState(() {
        _error = context.l10n.aiRewardedRequired;
        _serviceException = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _serviceException = null;
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
      if (!mounted) return;
      setState(() {
        _loading = false;
        _result = advice;
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (mounted && _scrollController.hasClients) {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    } on AIServiceException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _serviceException = e;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _copyResult() {
    final r = _result;
    if (r == null) return;
    final a = r.analysis;
    final buf = StringBuffer();
    buf.writeln(a.summary);
    if (a.possibleCauses.isNotEmpty) {
      buf.writeln();
      for (final c in a.possibleCauses) {
        buf.writeln('• $c');
      }
    }
    if (a.watchAtHome.isNotEmpty) {
      buf.writeln();
      buf.writeln(a.watchAtHome);
    }
    if (a.seekVetNow.isNotEmpty) {
      buf.writeln();
      buf.writeln(a.seekVetNow);
    }
    if (a.nextQuestions.isNotEmpty) {
      buf.writeln();
      for (final q in a.nextQuestions) {
        buf.writeln('? $q');
      }
    }
    if (a.disclaimer.isNotEmpty) {
      buf.writeln();
      buf.writeln(a.disclaimer);
    }
    Clipboard.setData(ClipboardData(text: buf.toString().trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.aiCopiedSuccess)),
    );
  }

  void _askAgain() {
    setState(() {
      _result = null;
      _error = null;
      _serviceException = null;
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
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
    final hasText = _symptomController.text.trim().isNotEmpty;
    final canSubmit = !_loading && hasText;

    return Scaffold(
      backgroundColor: scheme.surface,
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
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.lg),
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
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.aiSubtitle,
              style: textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: AppSpacing.lg),

            /// 输入区
            TextField(
              controller: _symptomController,
              decoration: InputDecoration(
                labelText: context.l10n.aiHint,
                border: const OutlineInputBorder(),
                hintText: context.l10n.aiHint,
              ),
              maxLines: 4,
              minLines: 3,
              onChanged: (_) => setState(() {
                _error = null;
                _serviceException = null;
              }),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(context.l10n.severity, style: textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  label: Text(context.l10n.severityGreen),
                  selected: _severity == Severity.green,
                  onSelected: _loading ? null : (_) => setState(() => _severity = Severity.green),
                ),
                ChoiceChip(
                  label: Text(context.l10n.severityYellow),
                  selected: _severity == Severity.yellow,
                  onSelected: _loading ? null : (_) => setState(() => _severity = Severity.yellow),
                ),
                ChoiceChip(
                  label: Text(context.l10n.severityRed),
                  selected: _severity == Severity.red,
                  onSelected: _loading ? null : (_) => setState(() => _severity = Severity.red),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
            if (_serviceException != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AppSurfaceCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                showShadow: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: scheme.error, size: 22),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _messageForServiceError(context, _serviceException!),
                        style: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: context.l10n.retry,
                      variant: AppButtonVariant.secondary,
                      loading: _loading,
                      onPressed: _loading ? null : _submit,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: context.l10n.getGuidance,
              variant: AppButtonVariant.primary,
              loading: _loading,
              onPressed: canSubmit ? _submit : null,
            ),
            if (_serviceException != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  context.l10n.aiSubtitle,
                  style: textTheme.bodySmall?.copyWith(color: scheme.outline),
                ),
              ),

            if (_result != null) ...[
              const SizedBox(height: AppSpacing.xl),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              Text(context.l10n.guidance, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.md),
              SymptomResultPanel(
                result: _result!,
                userSeverity: _severity,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: context.l10n.aiCopyResult,
                      variant: AppButtonVariant.secondary,
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      onPressed: _copyResult,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: context.l10n.aiAskAgain,
                      variant: AppButtonVariant.primary,
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      onPressed: _askAgain,
                    ),
                  ),
                ],
              ),
              if (kDebugMode &&
                  (_result!.detectedLanguage.isNotEmpty || _result!.responseLanguage.isNotEmpty)) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'detected=${_result!.detectedLanguage} · response=${_result!.responseLanguage}',
                  style: textTheme.bodySmall?.copyWith(color: scheme.outline, fontSize: 11),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

final aiServiceProvider = Provider<AIService>((ref) => AIService());
