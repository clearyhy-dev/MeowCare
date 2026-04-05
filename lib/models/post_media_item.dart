/// Single image or video URL in a post's ordered [media] list (Firestore).
class PostMediaItem {
  const PostMediaItem({
    required this.kind,
    required this.url,
    this.thumbnailUrl,
  });

  /// `'image'` | `'video'`
  final String kind;
  final String url;
  /// Required for video (poster / feed preview).
  final String? thumbnailUrl;

  bool get isVideo => kind == 'video';

  factory PostMediaItem.image(String url, {String? thumbnailUrl}) {
    return PostMediaItem(kind: 'image', url: url, thumbnailUrl: thumbnailUrl);
  }

  factory PostMediaItem.video(String url, String thumbnailUrl) {
    return PostMediaItem(kind: 'video', url: url, thumbnailUrl: thumbnailUrl);
  }

  Map<String, dynamic> toMap() {
    return {
      'type': kind,
      'url': url,
      if (thumbnailUrl != null && thumbnailUrl!.trim().isNotEmpty) 'thumbnailUrl': thumbnailUrl!.trim(),
    };
  }

  factory PostMediaItem.fromMap(Map<String, dynamic> m) {
    final t = (m['type'] as String? ?? '').toLowerCase();
    final isVid = t == 'video';
    return PostMediaItem(
      kind: isVid ? 'video' : 'image',
      url: m['url'] as String? ?? '',
      thumbnailUrl: m['thumbnailUrl'] as String?,
    );
  }
}
