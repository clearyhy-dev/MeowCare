import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/interstitial_ad_service.dart';

final adNavigationObserversProvider = Provider<List<NavigatorObserver>>((ref) {
  return [InterstitialNavigationObserver(ref)];
});

class InterstitialNavigationObserver extends NavigatorObserver {
  InterstitialNavigationObserver(this._ref);

  final Ref _ref;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (previousRoute == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ref.read(interstitialAdServiceProvider).onRoutePushed();
    });
  }
}
