import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kAppLocaleKey = 'app_locale';
const String _kAppCountryKey = 'app_country';

/// Google Play 下载/收入最多的约 20 个国家，并匹配应用支持的语言（en/zh/ja/ko/de/fr/es/ru）
const List<RegionOption> kSupportedRegions = [
  RegionOption(countryCode: '', locale: '', displayName: null), // 跟随系统
  RegionOption(countryCode: 'US', locale: 'en', displayName: 'United States'),
  RegionOption(countryCode: 'JP', locale: 'ja', displayName: '日本'),
  RegionOption(countryCode: 'KR', locale: 'ko', displayName: '한국'),
  RegionOption(countryCode: 'DE', locale: 'de', displayName: 'Deutschland'),
  RegionOption(countryCode: 'GB', locale: 'en', displayName: 'United Kingdom'),
  RegionOption(countryCode: 'TW', locale: 'zh', displayName: '台灣'),
  RegionOption(countryCode: 'CN', locale: 'zh', displayName: '中国'),
  RegionOption(countryCode: 'IN', locale: 'en', displayName: 'India'),
  RegionOption(countryCode: 'BR', locale: 'en', displayName: 'Brasil'),
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

/// 当前应用语言（由所选国家推导）。null = 跟随系统。
final appLocaleProvider = AsyncNotifierProvider<AppLocaleNotifier, Locale?>(AppLocaleNotifier.new);

/// 当前所选国家码，用于 Feed 按国家筛选。null/空 = 跟随系统时不按国家过滤（显示全部）。
final appCountryProvider = AsyncNotifierProvider<AppCountryNotifier, String?>(AppCountryNotifier.new);

class AppLocaleNotifier extends AsyncNotifier<Locale?> {
  @override
  Future<Locale?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kAppLocaleKey) ?? '';
    if (code.isEmpty) return null;
    return Locale(code);
  }

  Future<void> setLocale(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAppLocaleKey, code);
    state = AsyncData(code.isEmpty ? null : Locale(code));
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

/// 设置国家/地区：同时更新语言与国家码（供设置页国家选择器调用）
Future<void> setAppRegion(WidgetRef ref, String? countryCode) async {
  final prefs = await SharedPreferences.getInstance();
  final locale = countryCode == null || countryCode.isEmpty
      ? ''
      : (RegionOption.byCountryCode(countryCode)?.locale ?? 'en');
  await prefs.setString(_kAppCountryKey, countryCode ?? '');
  await prefs.setString(_kAppLocaleKey, locale);
  ref.invalidate(appLocaleProvider);
  ref.invalidate(appCountryProvider);
}

/// 语言码显示名（兼容旧逻辑）
String languageDisplayName(String code, BuildContext context) {
  switch (code) {
    case 'en':
      return 'English';
    case 'ja':
      return '日本語';
    case 'ko':
      return '한국어';
    case 'de':
      return 'Deutsch';
    case 'fr':
      return 'Français';
    case 'es':
      return 'Español';
    case 'zh':
      return '中文';
    case 'ru':
      return 'Русский';
    default:
      return code;
  }
}

