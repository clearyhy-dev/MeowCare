import 'package:flutter/material.dart';

/// 圆形网络头像，加载失败时显示占位图标，避免“看不到图”的问题。
class NetworkAvatar extends StatelessWidget {
  const NetworkAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 24,
    this.placeholder = const Icon(Icons.pets),
  });

  final String imageUrl;
  final double radius;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return CircleAvatar(radius: radius, child: placeholder);
    }
    return CircleAvatar(
      radius: radius,
      child: ClipOval(
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox(
                width: radius,
                height: radius,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          (loadingProgress.expectedTotalBytes ?? 1)
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => placeholder,
        ),
      ),
    );
  }
}
