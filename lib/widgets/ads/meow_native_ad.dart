import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/ads/ad_unit_ids.dart';

/// 模板原生广告（社区 Feed 列表内嵌）。
class MeowNativeAdTile extends StatefulWidget {
  const MeowNativeAdTile({super.key, required this.show});

  final bool show;

  @override
  State<MeowNativeAdTile> createState() => _MeowNativeAdTileState();
}

class _MeowNativeAdTileState extends State<MeowNativeAdTile> {
  NativeAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.show) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  @override
  void didUpdateWidget(MeowNativeAdTile oldWidget) {
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
    final scheme = Theme.of(context).colorScheme;
    final ad = NativeAd(
      adUnitId: AdUnitIds.nativeTemplate,
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _loaded = false);
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: scheme.surfaceContainerLow,
        cornerRadius: 12,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: scheme.onPrimary,
          backgroundColor: scheme.primary,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: scheme.onSurface,
          backgroundColor: Colors.transparent,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: scheme.onSurfaceVariant,
          backgroundColor: Colors.transparent,
        ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 320,
          child: AdWidget(ad: _ad!),
        ),
      ),
    );
  }
}
