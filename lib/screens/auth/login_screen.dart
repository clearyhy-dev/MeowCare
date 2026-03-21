import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/utils/l10n_ext.dart';
import '../../providers/user_provider.dart';


class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });
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
      final msg = _errorMessageForLogin(e);
      setState(() { _loading = false; _error = msg; });
    }
  }


  /// 把异常转成用户能看懂的提示（区分 Google 认证失败 vs Firestore 同步失败）
  String _errorMessageForLogin(dynamic e) {
    final s = e.toString().toLowerCase();
    if (s.contains('cloud_firestore') && s.contains('unavailable')) {
      return 'Google 登录成功，但同步资料失败（网络或 Firestore 不可用）。请检查网络、关闭 VPN 后重试，并确认 Firebase 已创建 Firestore。';
    }
    if (s.contains('12501') || s.contains('sign_in_failed') || s.contains('10')) {
      return 'Google 登录配置有误：请在 Firebase 项目设置中添加当前应用的 SHA-1 指纹，并重新下载 google-services.json。';
    }
    if (s.contains('network') || s.contains('socket')) {
      return '网络异常，请检查网络后重试。';
    }
    return e.toString();
  }


  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
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
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(context.l10n.appTitle, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(context.l10n.appSubtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 32),
                  if (_error != null) ...[
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    const SizedBox(height: 16),
                  ],
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _signInWithGoogle,
                    icon: const Icon(Icons.g_mobiledata),
                    label: Text(context.l10n.signInWithGoogle),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: context.l10n.email, border: const OutlineInputBorder()),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    validator: (v) => v == null || v.isEmpty ? context.l10n.enterEmail : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(labelText: context.l10n.password, border: const OutlineInputBorder()),
                    obscureText: true,
                    validator: (v) => v == null || v.isEmpty ? context.l10n.enterPassword : null,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loading ? null : _signInWithEmail,
                    child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(context.l10n.signIn),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.push(AppRouter.register),
                    child: Text(context.l10n.createAccount),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
