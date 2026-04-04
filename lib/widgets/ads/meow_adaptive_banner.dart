import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/ads/ad_unit_ids.dart';

/// 自适应锚定横幅；加载失败或 [show] 为 false 时不占位高度。
class MeowAdaptiveBanner extends StatefulWidget {
  const MeowAdaptiveBanner({super.key, required this.show});

  final bool show;

  @override
  State<MeowAdaptiveBanner> createState() => _MeowAdaptiveBannerState();
}

class _MeowAdaptiveBannerState extends State<MeowAdaptiveBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.show) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  @override
  void didUpdateWidget(MeowAdaptiveBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.show && !widget.show) {
      _disposeAd();
      setState(() => _loaded = false);
    } else if (!oldWidget.show && widget.show) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    if (!widget.show || !mounted) return;

    _disposeAd();
    final width = MediaQuery.sizeOf(context).width.truncate();
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null) return;

    final ad = BannerAd(
      adUnitId: AdUnitIds.anchoredBanner,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _loaded = false;
              _ad = null;
            });
          }
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  void _disposeAd() {
    _ad?.dispose();
    _ad = null;
  }

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show || !_loaded || _ad == null) {
      return const SizedBox.shrink();
    }
    return Center(
      child: SizedBox(
        width: _ad!.size.width.toDouble(),
        height: _ad!.size.height.toDouble(),
        child: AdWidget(ad: _ad!),
      ),
    );
  }
}
