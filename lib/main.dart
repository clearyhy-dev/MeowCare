import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'core/router/app_router.dart' show AppRouter, GoRouterRefreshNotifier;
import 'core/theme/app_theme.dart';
import 'generated/l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await MobileAds.instance.initialize();
  runApp(const ProviderScope(child: MeowCareApp()));
}

class MeowCareApp extends ConsumerWidget {
  const MeowCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refreshNotifier = ref.watch(routerRefreshNotifierProvider);
    final authAsync = ref.watch(authStateProvider);
    final profileAsync = ref.watch(currentUserAsyncProvider);
    refreshNotifier.update(authAsync, profileAsync);

    final router = ref.watch(appRouterProvider);
    final localeAsync = ref.watch(appLocaleProvider);
    final manualLocale = localeAsync.valueOrNull;

    final supported = AppLocalizations.supportedLocales;
    return MaterialApp.router(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: supported,
      locale: manualLocale,
      localeResolutionCallback: (Locale? deviceLocale, Iterable<Locale> supportedLocales) {
        return resolveDeviceLocale(deviceLocale, supportedLocales.toList());
      },
      routerConfig: router,
    );
  }
}

final routerRefreshNotifierProvider = Provider<GoRouterRefreshNotifier>((ref) {
  return GoRouterRefreshNotifier();
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerRefreshNotifierProvider);
  return AppRouter.createRouter(notifier);
});
