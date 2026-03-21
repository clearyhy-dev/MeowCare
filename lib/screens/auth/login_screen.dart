import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/utils/l10n_ext.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../providers/user_provider.dart';

/// 用户端仅 Google 登录；视觉与 Feed 一致的社区风（紧凑、轻阴影、信息优先）。
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      if (!mounted) return;
      ref.invalidate(currentUserAsyncProvider);
      final newUser = await ref.read(currentUserAsyncProvider.future);
      if (!mounted) return;
      setState(() => _loading = false);
      final hasFamily = newUser?.familyId != null && newUser!.familyId!.isNotEmpty;
      if (hasFamily) {
        context.go(AppRouter.home);
      } else {
        context.go(AppRouter.createFamily);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = _errorMessageForLogin(e, context.l10n);
      setState(() {
        _loading = false;
        _error = msg;
      });
    }
  }

  String _errorMessageForLogin(dynamic e, AppLocalizations l10n) {
    final s = e.toString().toLowerCase();
    if (s.contains('cloud_firestore') && s.contains('unavailable')) {
      return l10n.loginErrorFirestoreSync;
    }
    if (s.contains('12501') || s.contains('sign_in_failed') || s.contains('10')) {
      return l10n.loginErrorGoogleConfig;
    }
    if (s.contains('network') || s.contains('socket')) {
      return l10n.loginErrorNetwork;
    }
    return e.toString();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = scheme.outline.withValues(alpha: 0.35);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Text(
                  context.l10n.appTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.appSubtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.l10n.signIn,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.signInWithGoogle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 20),
                      if (_error != null) ...[
                        Text(
                          _error!,
                          style: TextStyle(color: scheme.error, fontSize: 13, height: 1.35),
                        ),
                        const SizedBox(height: 16),
                      ],
                      OutlinedButton(
                        onPressed: _loading ? null : _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.onSurface,
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _loading
                            ? SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: scheme.primary,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.account_circle_outlined, size: 22, color: scheme.primary),
                                  const SizedBox(width: 10),
                                  Text(
                                    context.l10n.signInWithGoogle,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  context.l10n.goToSettingsToSignIn,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
