import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'generated/l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/user_provider.dart';

/// Google Play 常见 30 国/地区 → 应用支持的语言（en, ja, ko, de, fr, es, zh, ru）
const Map<String, String> _countryToLanguage = {
  'US': 'en', 'GB': 'en', 'AU': 'en', 'IN': 'en', 'CA': 'en', 'PH': 'en', 'MY': 'en', 'SG': 'en', 'IE': 'en', 'NZ': 'en', 'ZA': 'en',
  'JP': 'ja', 'KR': 'ko',
  'DE': 'de', 'AT': 'de', 'CH': 'de',
  'FR': 'fr', 'BE': 'fr',
  'ES': 'es', 'MX': 'es', 'AR': 'es', 'CO': 'es', 'CL': 'es', 'PE': 'es', 'EC': 'es',
  'CN': 'zh', 'TW': 'zh', 'HK': 'zh',
  'RU': 'ru', 'BY': 'ru', 'KZ': 'ru', 'UA': 'ru',
  'BR': 'en', 'IT': 'en', 'ID': 'en', 'TR': 'en', 'TH': 'en', 'NL': 'en', 'SA': 'en', 'SE': 'en', 'PL': 'en', 'VN': 'en',
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
    final locale = localeAsync.valueOrNull;

    final supported = AppLocalizations.supportedLocales;
    return MaterialApp.router(
      title: 'MeowCare',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: supported,
      locale: locale,
      localeResolutionCallback: (Locale? deviceLocale, Iterable<Locale> supportedLocales) {
        final list = supportedLocales.toList();
        if (list.isEmpty) return null;
        if (deviceLocale == null) return list.first;
        for (final s in list) {
          if (s.languageCode == deviceLocale.languageCode) return s;
        }
        final country = deviceLocale.countryCode?.toUpperCase();
        final lang = country != null ? _countryToLanguage[country] : null;
        if (lang != null) {
          for (final s in list) {
            if (s.languageCode == lang) return s;
          }
        }
        for (final s in list) {
          if (s.languageCode == 'en') return s;
        }
        return list.first;
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
