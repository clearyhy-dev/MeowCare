import 'package:flutter/foundation.dart';

/// AdMob 应用 ID 见 `AndroidManifest.xml` 与 `ios/Runner/Info.plist`。
///
/// **上架前**：将各 `*Release` 换为 AdMob 控制台对应广告单元；调试使用 Google 测试 ID。
class AdUnitIds {
  AdUnitIds._();

  // --- 测试 ID（Google 官方）---
  static const String _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const String _testNativeAndroid = 'ca-app-pub-3940256099942544/2247696110';
  static const String _testNativeIos = 'ca-app-pub-3940256099942544/3986624511';
  static const String _testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';
  static const String _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';
  static const String _testAppOpenAndroid = 'ca-app-pub-3940256099942544/9257395921';
  static const String _testAppOpenIos = 'ca-app-pub-3940256099942544/5575463023';

  /// 正式 — 请替换
  static const String androidBannerRelease = '';
  static const String iosBannerRelease = '';
  static const String androidNativeRelease = '';
  static const String iosNativeRelease = '';
  static const String androidRewardedRelease = '';
  static const String iosRewardedRelease = '';
  static const String androidInterstitialRelease = '';
  static const String iosInterstitialRelease = '';
  static const String androidAppOpenRelease = '';
  static const String iosAppOpenRelease = '';

  static String _pick({
    required String testAndroid,
    required String testIos,
    required String releaseAndroid,
    required String releaseIos,
  }) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        if (kReleaseMode && releaseAndroid.isNotEmpty) return releaseAndroid;
        return testAndroid;
      case TargetPlatform.iOS:
        if (kReleaseMode && releaseIos.isNotEmpty) return releaseIos;
        return testIos;
      default:
        return testAndroid;
    }
  }

  static String get anchoredBanner => _pick(
        testAndroid: _testBannerAndroid,
        testIos: _testBannerIos,
        releaseAndroid: androidBannerRelease,
        releaseIos: iosBannerRelease,
      );

  static String get nativeTemplate => _pick(
        testAndroid: _testNativeAndroid,
        testIos: _testNativeIos,
        releaseAndroid: androidNativeRelease,
        releaseIos: iosNativeRelease,
      );

  static String get rewarded => _pick(
        testAndroid: _testRewardedAndroid,
        testIos: _testRewardedIos,
        releaseAndroid: androidRewardedRelease,
        releaseIos: iosRewardedRelease,
      );

  static String get interstitial => _pick(
        testAndroid: _testInterstitialAndroid,
        testIos: _testInterstitialIos,
        releaseAndroid: androidInterstitialRelease,
        releaseIos: iosInterstitialRelease,
      );

  static String get appOpen => _pick(
        testAndroid: _testAppOpenAndroid,
        testIos: _testAppOpenIos,
        releaseAndroid: androidAppOpenRelease,
        releaseIos: iosAppOpenRelease,
      );
}
