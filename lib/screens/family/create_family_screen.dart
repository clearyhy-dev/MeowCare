import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/utils/l10n_ext.dart';
import '../../providers/family_provider.dart';
import '../../providers/user_provider.dart';

class CreateFamilyScreen extends ConsumerStatefulWidget {
  const CreateFamilyScreen({super.key});

  @override
  ConsumerState<CreateFamilyScreen> createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends ConsumerState<CreateFamilyScreen> {
  bool _loading = false;
  String? _inviteCode;
  String? _error;

  Future<void> _createFamily() async {
    final uid = ref.read(authServiceProvider).currentUid;
    if (uid == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final family = await ref.read(familyServiceProvider).createFamily(uid);
      if (mounted) setState(() { _loading = false; _inviteCode = family.inviteCode; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.createFamily)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _inviteCode != null ? _buildInviteView(context) : _buildCreateView(context),
        ),
      ),
    );
  }

  Widget _buildCreateView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(context.l10n.createFamilyDesc, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        if (_error != null) ...[
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 16),
        ],
        FilledButton(
          onPressed: _loading ? null : _createFamily,
          child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(context.l10n.createFamily),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go(AppRouter.joinFamily),
          child: Text(context.l10n.iHaveInviteCode),
        ),
      ],
    );
  }

  Widget _buildInviteView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.yourInviteCode, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        SelectableText(_inviteCode!, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => context.go(AppRouter.home),
          child: Text(context.l10n.continueToApp),
        ),
      ],
    );
  }
}
