import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/l10n_ext.dart';
import '../../providers/cat_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/ai_service.dart';

class AIScreen extends ConsumerStatefulWidget {
  const AIScreen({super.key});

  @override
  ConsumerState<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends ConsumerState<AIScreen> {
  final _symptomController = TextEditingController();
  Severity _severity = Severity.green;
  bool _loading = false;
  String? _response;

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
    final locale = ref.read(effectiveUILanguageCodeProvider);
    final uid = ref.read(authServiceProvider).currentUid;

    if (uid == null) return;
    final status = await ref.read(subscriptionStatusProvider.future);
    final isPro = status == SubscriptionStatus.pro;
    final result = await ref.read(aiServiceProvider).checkCanRequestAI(uid, isPro);
    if (!result.canRequest) {
      setState(() => _error = context.l10n.aiErrorFreeLimit(AppConstants.freeAiRequestsPerDay));
      return;
    }
    setState(() { _loading = true; _error = null; _response = null; });
    try {
      final request = await ref.read(aiServiceProvider).submitRequest(uid, symptom, _severity);
      final result = await ref.read(aiServiceProvider).getAIResponse(
            request.requestId,
            symptom,
            _severity,
            locale: locale,
          );
      if (mounted) setState(() { _loading = false; _response = result.advice; });
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

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.aiSymptomSupport),
        actions: [
          if (!isPro)
            TextButton(
              onPressed: () => context.push('${AppRouter.home}subscription'),
              child: Text(context.l10n.pro),
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
                Icon(Icons.pets, color: Theme.of(context).colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text(aiTitle, style: Theme.of(context).textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.aiSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
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
            Text(context.l10n.severity, style: Theme.of(context).textTheme.labelLarge),
            Row(
              children: [
                Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(context.l10n.severityGreen), selected: _severity == Severity.green, onSelected: (_) => setState(() => _severity = Severity.green))),
                Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(context.l10n.severityYellow), selected: _severity == Severity.yellow, onSelected: (_) => setState(() => _severity = Severity.yellow))),
                Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(context.l10n.severityRed), selected: _severity == Severity.red, onSelected: (_) => setState(() => _severity = Severity.red))),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(context.l10n.getGuidance),
            ),
            if (_response != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              Text(context.l10n.guidance, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_response ?? ''),

              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.aiSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),

            ],
          ],
        ),
      ),
    );
  }
}

final aiServiceProvider = Provider<AIService>((ref) => AIService());

