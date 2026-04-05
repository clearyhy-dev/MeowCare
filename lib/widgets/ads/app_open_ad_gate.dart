import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/app_launch.dart';
import '../../core/ads/ad_unit_ids.dart';
import '../../core/constants/enums.dart';
import '../../providers/ads_visibility_provider.dart';
import '../../providers/subscription_provider.dart';

/// 第 [minLaunchCount] 次及以后冷启动时尝试展示开屏广告（仅移动平台、非 Pro）。
class AppOpenAdGate extends ConsumerStatefulWidget {
  const AppOpenAdGate({super.key, required this.child, this.minLaunchCount = 3});

  final Widget child;
  final int minLaunchCount;

  @override
  ConsumerState<AppOpenAdGate> createState() => _AppOpenAdGateState();
}

class _AppOpenAdGateState extends ConsumerState<AppOpenAdGate> {
  bool _tried = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  Future<void> _maybeShow() async {
    if (_tried) return;
    if (appLaunchCount < widget.minLaunchCount) return;
    if (!ref.read(adsSupportedPlatformProvider)) return;
    final status = await ref.read(subscriptionStatusProvider.future);
    if (!mounted) return;
    if (status == SubscriptionStatus.pro) return;
    _tried = true;
    await AppOpenAd.load(
      adUnitId: AdUnitIds.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (a) => a.dispose(),
            onAdFailedToShowFullScreenContent: (a, _) => a.dispose(),
          );
          ad.show();
        },
        onAdFailedToLoad: (_) {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
