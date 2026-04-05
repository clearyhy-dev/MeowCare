import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/ads/ad_unit_ids.dart';
import '../providers/ads_visibility_provider.dart';

final interstitialAdServiceProvider = Provider<InterstitialAdService>((ref) {
  final s = InterstitialAdService(ref);
  ref.onDispose(s.dispose);
  return s;
});

/// 每 2 次页面跳转尝试展示 1 次插屏；带最短间隔，避免过密。
class InterstitialAdService {
  InterstitialAdService(this._ref);

  final Ref _ref;
  int _routePushes = 0;
  DateTime? _lastShownAt;

  static const _everyNavigations = 2;
  static const _minInterval = Duration(seconds: 90);

  void onRoutePushed() {
    if (!_ref.read(shouldShowAdsProvider)) return;
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    _routePushes++;
    if (_routePushes % _everyNavigations != 0) return;
    final now = DateTime.now();
    if (_lastShownAt != null && now.difference(_lastShownAt!) < _minInterval) return;
    _loadAndShow();
  }

  Future<void> _loadAndShow() async {
    await InterstitialAd.load(
      adUnitId: AdUnitIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (a) {
              a.dispose();
            },
            onAdFailedToShowFullScreenContent: (a, _) {
              a.dispose();
            },
          );
          _lastShownAt = DateTime.now();
          ad.show();
        },
        onAdFailedToLoad: (_) {},
      ),
    );
  }

  void dispose() {}
}
