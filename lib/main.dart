import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_launch.dart';
import 'core/router/app_router.dart' show AppRouter, GoRouterRefreshNotifier;
import 'core/theme/app_theme.dart';
import 'generated/l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/user_provider.dart';
import 'widgets/ads/ad_navigation_observer.dart';
import 'widgets/ads/app_open_ad_gate.dart';

const _kAppLaunchCountKey = 'app_launch_count';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await MobileAds.instance.initialize();
  final prefs = await SharedPreferences.getInstance();
  appLaunchCount = (prefs.getInt(_kAppLaunchCountKey) ?? 0) + 1;
  await prefs.setInt(_kAppLaunchCountKey, appLaunchCount);
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
    return AppOpenAdGate(
      child: MaterialApp.router(
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
      ),
    );
  }
}

final routerRefreshNotifierProvider = Provider<GoRouterRefreshNotifier>((ref) {
  return GoRouterRefreshNotifier();
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerRefreshNotifierProvider);
  final observers = ref.watch(adNavigationObserversProvider);
  return AppRouter.createRouter(notifier, observers: observers);
});
