import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_radii.dart';
import '../../models/post_media_item.dart';

/// Swipeable images / videos in post order; videos auto-play when the page is active.
class PostMediaCarousel extends StatefulWidget {
  const PostMediaCarousel({
    super.key,
    required this.items,
    this.borderRadius,
    this.videoMuted = true,
  });

  final List<PostMediaItem> items;
  final BorderRadius? borderRadius;
  final bool videoMuted;

  @override
  State<PostMediaCarousel> createState() => _PostMediaCarouselState();
}

class _PostMediaCarouselState extends State<PostMediaCarousel> {
  late final PageController _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final radius = widget.borderRadius ?? BorderRadius.circular(AppRadii.sm);

    return ClipRRect(
      borderRadius: radius,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: items.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, index) {
                final item = items[index];
                if (item.isVideo) {
                  return _NetworkVideoSlide(
                    key: ValueKey('video-$index-${item.url}'),
                    url: item.url,
                    isActive: index == _page,
                    muted: widget.videoMuted,
                  );
                }
                return Image.network(
                  item.url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => ColoredBox(
                    color: scheme.surfaceContainerHighest,
                    child: Icon(Icons.broken_image_outlined, color: scheme.onSurfaceVariant),
                  ),
                );
              },
            ),
            if (items.length > 1)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    items.length,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 8 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? scheme.onSurface.withValues(alpha: 0.92)
                            : scheme.onSurface.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NetworkVideoSlide extends StatefulWidget {
  const _NetworkVideoSlide({
    super.key,
    required this.url,
    required this.isActive,
    required this.muted,
  });

  final String url;
  final bool isActive;
  final bool muted;

  @override
  State<_NetworkVideoSlide> createState() => _NetworkVideoSlideState();
}

class _NetworkVideoSlideState extends State<_NetworkVideoSlide> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize()
          .then((_) {
            if (!mounted) return;
            final c = _controller!;
            c.setLooping(true);
            c.setVolume(widget.muted ? 0 : 1);
            setState(() {});
            if (widget.isActive) {
              c.play();
            }
          })
          .catchError((_) {
            if (mounted) setState(() => _failed = true);
          });
  }

  @override
  void didUpdateWidget(covariant _NetworkVideoSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (widget.isActive && !oldWidget.isActive) {
      c.play();
    } else if (!widget.isActive && oldWidget.isActive) {
      c.pause();
    }
    if (widget.muted != oldWidget.muted) {
      c.setVolume(widget.muted ? 0 : 1);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_failed) {
      return ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Icon(Icons.videocam_off_outlined, color: scheme.onSurfaceVariant, size: 40),
      );
    }
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return ColoredBox(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: c.value.size.width,
          height: c.value.size.height,
          child: VideoPlayer(c),
        ),
      ),
    );
  }
}
