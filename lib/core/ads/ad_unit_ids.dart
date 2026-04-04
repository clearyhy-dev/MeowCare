import 'package:flutter/foundation.dart';

/// AdMob 应用 ID 见 `AndroidManifest.xml` 与 `ios/Runner/Info.plist`。
///
/// **上架前**：将 [androidBannerRelease] / [iosBannerRelease] 换为 AdMob 后台创建的
/// 横幅广告单元 ID；调试时使用 Google 官方测试 ID（见下方）。
class AdUnitIds {
  AdUnitIds._();

  /// Google 官方测试横幅（Android）
  static const String _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';

  /// Google 官方测试横幅（iOS）
  static const String _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';

  /// 正式环境横幅 — 请在 AdMob 控制台创建后替换（勿提交测试 ID 到生产）。
  static const String androidBannerRelease = '';
  static const String iosBannerRelease = '';

  /// 自适应横幅广告单元（按平台选择）。
  static String get anchoredBanner {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        if (kReleaseMode && androidBannerRelease.isNotEmpty) {
          return androidBannerRelease;
        }
        return _testBannerAndroid;
      case TargetPlatform.iOS:
        if (kReleaseMode && iosBannerRelease.isNotEmpty) {
          return iosBannerRelease;
        }
        return _testBannerIos;
      default:
        return _testBannerAndroid;
    }
  }
}
