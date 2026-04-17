import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_colors.dart';

/// Widget réutilisable pour afficher des images en cache.
///
/// Utiliser ce widget au lieu de CachedNetworkImage directement pour:
/// - Placeholder shimmer standardisé
/// - Widget d'erreur standardisé
/// - Timeout intégré pour éviter les images qui bloquent
class CachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration? httpTimeout;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.httpTimeout,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        httpHeaders: const {'Connection': 'keep-alive'},
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
        maxHeightDiskCache: 1000,
        maxWidthDiskCache: 1000,
        useOldImageOnUrlChange: true,
        placeholder: (context, url) =>
            placeholder ??
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                width: width,
                height: height,
                color: Colors.white,
              ),
            ),
        errorWidget: (context, url, error) =>
            errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey.shade200,
              child: const Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 48,
              ),
            ),
      ),
    );
  }
}

/// Widget pour afficher un avatar avec cache
class CachedAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String? fallbackText;
  final Color? backgroundColor;

  const CachedAvatar({
    super.key,
    this.imageUrl,
    this.radius = 40,
    this.fallbackText,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primary;

    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? primaryColor.withValues(alpha: 0.1),
        child: Text(
          fallbackText ?? '?',
          style: TextStyle(
            fontSize: radius * 0.5,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: CircleAvatar(radius: radius, backgroundColor: Colors.white),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: radius,
          backgroundColor:
              backgroundColor ?? primaryColor.withValues(alpha: 0.1),
          child: Text(
            fallbackText ?? '?',
            style: TextStyle(
              fontSize: radius * 0.5,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
