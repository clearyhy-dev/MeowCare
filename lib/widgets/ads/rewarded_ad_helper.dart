import 'dart:async';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/ads/ad_unit_ids.dart';
import '../../core/constants/enums.dart';
import '../../providers/ads_visibility_provider.dart';
import '../../providers/subscription_provider.dart';

/// AI 使用前展示激励视频。非移动平台或 Pro 直接返回 true。
Future<bool> showRewardedForAiUse(WidgetRef ref) async {
  if (!ref.read(adsSupportedPlatformProvider)) return true;
  if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS) {
    return true;
  }
  final sub = await ref.read(subscriptionStatusProvider.future);
  if (sub == SubscriptionStatus.pro) return true;
  final c = Completer<bool>();
  RewardedAd.load(
    adUnitId: AdUnitIds.rewarded,
    request: const AdRequest(),
    rewardedAdLoadCallback: RewardedAdLoadCallback(
      onAdLoaded: (ad) {
        var earned = false;
        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (a) {
            a.dispose();
            if (!c.isCompleted) c.complete(earned);
          },
          onAdFailedToShowFullScreenContent: (a, _) {
            a.dispose();
            if (!c.isCompleted) c.complete(false);
          },
        );
        ad.show(
          onUserEarnedReward: (_, __) {
            earned = true;
          },
        );
      },
      onAdFailedToLoad: (_) {
        if (!c.isCompleted) c.complete(false);
      },
    ),
  );
  return c.future;
}
