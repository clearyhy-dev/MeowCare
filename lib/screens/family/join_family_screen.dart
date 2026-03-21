import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/family_limit_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/l10n_ext.dart';
import '../../providers/family_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/upgrade_dialog.dart';

class JoinFamilyScreen extends ConsumerStatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  ConsumerState<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends ConsumerState<JoinFamilyScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = context.l10n.enterInviteCode);
      return;
    }
    final uid = ref.read(authServiceProvider).currentUid;
    if (uid == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final family = await ref.read(familyServiceProvider).joinFamilyByInviteCode(code, uid);
      if (mounted) {
        setState(() => _loading = false);
        if (family != null) {
          context.go(AppRouter.home);
        } else {
          setState(() => _error = context.l10n.invalidCode);
        }
      }
    } on FamilyLimitReachedException {
      if (mounted) {
        setState(() => _loading = false);
        showUpgradeDialog(context, onSeePro: () => context.push('${AppRouter.home}subscription'));
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.joinFamily),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go(AppRouter.createFamily)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(labelText: context.l10n.inviteCode, border: const OutlineInputBorder()),
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() => _error = null),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _join,

                child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(context.l10n.join),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(AppRouter.createFamily),
                child: Text(context.l10n.createFamilyInstead),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

