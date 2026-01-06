/// ==========================================
/// صور محسنة (04-assets-optimization.md)
/// ==========================================
///
/// هذا الملف يطبق:
/// - معيار 4: تحسين الأصول والصور
/// - تحديد cacheWidth/cacheHeight
/// - Lazy loading للصور
/// - Placeholder أثناء التحميل
library;

import 'package:flutter/material.dart';

/// صورة شبكة محسنة
class OptimizedNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // حساب أبعاد الكاش بناءً على كثافة البكسل
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final cacheWidth = width != null ? (width! * pixelRatio).toInt() : null;
    final cacheHeight = height != null ? (height! * pixelRatio).toInt() : null;

    return SizedBox(
      width: width,
      height: height,
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        // تحسين الذاكرة بتحديد حجم الكاش
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        // Placeholder أثناء التحميل
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              _DefaultPlaceholder(
                progress: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              );
        },
        // معالجة الأخطاء
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? const _DefaultErrorWidget();
        },
      ),
    );
  }
}

/// Placeholder افتراضي
class _DefaultPlaceholder extends StatelessWidget {
  final double? progress;

  const _DefaultPlaceholder({this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: progress != null
            ? CircularProgressIndicator(value: progress)
            : const CircularProgressIndicator(),
      ),
    );
  }
}

/// Widget خطأ افتراضي
class _DefaultErrorWidget extends StatelessWidget {
  const _DefaultErrorWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey,
          size: 48,
        ),
      ),
    );
  }
}

/// صورة أصول محسنة
class OptimizedAssetImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;

  const OptimizedAssetImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final cacheWidth = width != null ? (width! * pixelRatio).toInt() : null;
    final cacheHeight = height != null ? (height! * pixelRatio).toInt() : null;

    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }
}

/// Skeleton للصور أثناء التحميل
class ImageSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ImageSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<ImageSkeleton> createState() => _ImageSkeletonState();
}

class _ImageSkeletonState extends State<ImageSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
            ),
          ),
        );
      },
    );
  }
}
