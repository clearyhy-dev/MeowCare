import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../generated/l10n/app_localizations.dart';

const String _kAppLocaleKey = 'app_locale';
const String _kAppCountryKey = 'app_country';

/// 与 `app_*.arb` / gen-l10n 一致的应用界面语言。
const List<String> kSupportedAppLanguageCodes = [
  'en',
  'zh',
  'ja',
  'es',
  'fr',
  'de',
  'pt',
  'ru',
  'ko',
];

/// 国家/地区码 → 应用支持的语言码（用于无手动语言时按设备 region 推断）。
const Map<String, String> kCountryCodeToLanguage = {
  'US': 'en',
  'GB': 'en',
  'AU': 'en',
  'IN': 'en',
  'CA': 'en',
  'PH': 'en',
  'MY': 'en',
  'SG': 'en',
  'IE': 'en',
  'NZ': 'en',
  'ZA': 'en',
  'JP': 'ja',
  'KR': 'ko',
  'DE': 'de',
  'AT': 'de',
  'CH': 'de',
  'FR': 'fr',
  'BE': 'fr',
  'ES': 'es',
  'MX': 'es',
  'AR': 'es',
  'CO': 'es',
  'CL': 'es',
  'PE': 'es',
  'EC': 'es',
  'CN': 'zh',
  'TW': 'zh',
  'HK': 'zh',
  'RU': 'ru',
  'BY': 'ru',
  'KZ': 'ru',
  'UA': 'ru',
  'BR': 'pt',
  'PT': 'pt',
  'IT': 'en',
  'ID': 'en',
  'TR': 'en',
  'TH': 'en',
  'NL': 'en',
  'SA': 'en',
  'SE': 'en',
  'PL': 'en',
  'VN': 'en',
};

/// Feed 等地区筛选选项（与语言设置解耦）。
const List<RegionOption> kSupportedRegions = [
  RegionOption(countryCode: '', locale: '', displayName: null),
  RegionOption(countryCode: 'US', locale: 'en', displayName: 'United States'),
  RegionOption(countryCode: 'JP', locale: 'ja', displayName: '日本'),
  RegionOption(countryCode: 'KR', locale: 'ko', displayName: '한국'),
  RegionOption(countryCode: 'DE', locale: 'de', displayName: 'Deutschland'),
  RegionOption(countryCode: 'GB', locale: 'en', displayName: 'United Kingdom'),
  RegionOption(countryCode: 'TW', locale: 'zh', displayName: '台灣'),
  RegionOption(countryCode: 'CN', locale: 'zh', displayName: '中国'),
  RegionOption(countryCode: 'IN', locale: 'en', displayName: 'India'),
  RegionOption(countryCode: 'BR', locale: 'pt', displayName: 'Brasil'),
  RegionOption(countryCode: 'MX', locale: 'es', displayName: 'México'),
  RegionOption(countryCode: 'FR', locale: 'fr', displayName: 'France'),
  RegionOption(countryCode: 'CA', locale: 'en', displayName: 'Canada'),
  RegionOption(countryCode: 'AU', locale: 'en', displayName: 'Australia'),
  RegionOption(countryCode: 'ES', locale: 'es', displayName: 'España'),
  RegionOption(countryCode: 'IT', locale: 'en', displayName: 'Italy'),
  RegionOption(countryCode: 'ID', locale: 'en', displayName: 'Indonesia'),
  RegionOption(countryCode: 'RU', locale: 'ru', displayName: 'Россия'),
  RegionOption(countryCode: 'TH', locale: 'en', displayName: 'Thailand'),
  RegionOption(countryCode: 'VN', locale: 'en', displayName: 'Vietnam'),
  RegionOption(countryCode: 'TR', locale: 'en', displayName: 'Türkiye'),
  RegionOption(countryCode: 'PT', locale: 'pt', displayName: 'Portugal'),
];

class RegionOption {
  final String countryCode;
  final String locale;
  final String? displayName;

  const RegionOption({required this.countryCode, required this.locale, this.displayName});

  static RegionOption? byCountryCode(String code) {
    if (code.isEmpty) return kSupportedRegions.first;
    for (final r in kSupportedRegions) {
      if (r.countryCode == code) return r;
    }
    return null;
  }
}

/// `null` = 跟随系统；非空 = 用户固定的界面语言。
final appLocaleProvider = AsyncNotifierProvider<AppLocaleNotifier, Locale?>(AppLocaleNotifier.new);

final appCountryProvider = AsyncNotifierProvider<AppCountryNotifier, String?>(AppCountryNotifier.new);

/// 当前实际用于 API / 发帖 `language` 的语言码（手动或解析后的系统语言）。
final effectiveUILanguageCodeProvider = Provider<String>((ref) {
  final async = ref.watch(appLocaleProvider);
  final manual = async.valueOrNull;
  final supported = AppLocalizations.supportedLocales.toList();
  if (manual != null) {
    final c = manual.languageCode;
    if (kSupportedAppLanguageCodes.contains(c)) return c;
    return 'en';
  }
  final device = WidgetsBinding.instance.platformDispatcher.locale;
  return resolveDeviceLocale(device, supported).languageCode;
});

class AppLocaleNotifier extends AsyncNotifier<Locale?> {
  @override
  Future<Locale?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kAppLocaleKey) ?? '';
    if (code.isEmpty) return null;
    return Locale(code);
  }

  /// `null` 或 `''` → 跟随系统；否则为固定语言码。
  Future<void> setLanguageCode(String? languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = (languageCode == null || languageCode.isEmpty) ? '' : languageCode;
    await prefs.setString(_kAppLocaleKey, normalized);
    state = AsyncData(normalized.isEmpty ? null : Locale(normalized));
  }
}

class AppCountryNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kAppCountryKey) ?? '';
    return code.isEmpty ? null : code;
  }

  Future<void> setCountry(String? countryCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAppCountryKey, countryCode ?? '');
    state = AsyncData(countryCode?.isEmpty == true ? null : countryCode);
  }
}

/// 仅更新 Feed 国家筛选，不修改界面语言。
Future<void> setAppRegion(WidgetRef ref, String? countryCode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kAppCountryKey, countryCode ?? '');
  ref.invalidate(appCountryProvider);
}

/// 跟随系统时：根据设备 [Locale] 解析为 [supported] 中的一项（含 zh*/pt* 归一、国家码映射、回退 en）。
Locale resolveDeviceLocale(Locale? deviceLocale, List<Locale> supported) {
  if (supported.isEmpty) return const Locale('en');
  if (deviceLocale == null) return _firstEnglishOrFirst(supported);

  final lang = deviceLocale.languageCode.toLowerCase();
  if (lang == 'zh') {
    return _pickSupported('zh', supported);
  }
  if (lang == 'pt') {
    return _pickSupported('pt', supported);
  }
  for (final s in supported) {
    if (s.languageCode.toLowerCase() == lang) {
      return Locale(s.languageCode);
    }
  }
  final cc = deviceLocale.countryCode?.toUpperCase();
  if (cc != null) {
    final mapped = kCountryCodeToLanguage[cc];
    if (mapped != null) {
      return _pickSupported(mapped, supported);
    }
  }
  return _pickSupported('en', supported);
}

Locale _pickSupported(String languageCode, List<Locale> supported) {
  for (final s in supported) {
    if (s.languageCode == languageCode) return Locale(s.languageCode);
  }
  if (languageCode != 'en') {
    return _pickSupported('en', supported);
  }
  return supported.first;
}

Locale _firstEnglishOrFirst(List<Locale> supported) {
  for (final s in supported) {
    if (s.languageCode == 'en') return const Locale('en');
  }
  return supported.first;
}
