import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/enums.dart';
import 'subscription_provider.dart';

/// 仅在 Android / iOS 展示横幅；桌面与 Web 不加载。
final adsSupportedPlatformProvider = Provider<bool>((ref) {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      return true;
    default:
      return false;
  }
});

/// Pro 订阅用户不展示广告；加载中暂不展示，避免 Pro 用户闪一下广告。
final shouldShowAdsProvider = Provider<bool>((ref) {
  if (!ref.watch(adsSupportedPlatformProvider)) return false;
  final async = ref.watch(subscriptionStatusProvider);
  return async.when(
    data: (s) => s != SubscriptionStatus.pro,
    loading: () => false,
    error: (_, __) => true,
  );
});
