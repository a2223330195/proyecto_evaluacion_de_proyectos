import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:coachhub/widgets/skeleton_loaders/animated_shimmer.dart';

/// Widget optimizado para mostrar imágenes con lazy loading y caching
/// 🛡️ MÓDULO 5: Fase 5.5 - Lazy Images
///
/// Features:
/// - CachedNetworkImage con cache automático
/// - Skeleton shimmer durante carga
/// - Error widget con icono fallback
/// - Fade-in animation
/// - Memory efficient
class LazyCachedImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxShape shape;
  final BorderRadius? borderRadius;
  final Color? placeholderColor;
  final IconData? errorIcon;
  final Duration fadeDuration;
  final BoxFit fit;

  const LazyCachedImage({
    super.key,
    required this.imageUrl,
    this.width = 60,
    this.height = 60,
    this.shape = BoxShape.circle,
    this.borderRadius,
    this.placeholderColor,
    this.errorIcon = Icons.image_not_supported_outlined,
    this.fadeDuration = const Duration(milliseconds: 300),
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return _buildContainer(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: fadeDuration,
        fadeOutDuration: fadeDuration,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildErrorWidget(),
        memCacheWidth: width.isFinite ? (width * 2).toInt() : null,
        memCacheHeight: height.isFinite ? (height * 2).toInt() : null,
      ),
    );
  }

  /// Contenedor según forma (círculo o rectángulo)
  Widget _buildContainer({required Widget child}) {
    if (shape == BoxShape.circle) {
      return ClipOval(child: child);
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }

    return child;
  }

  /// Placeholder con efecto shimmer
  Widget _buildPlaceholder() {
    return AnimatedShimmer(
      duration: const Duration(milliseconds: 1000),
      child: Container(
        width: width,
        height: height,
        color: placeholderColor ?? Colors.grey[300],
      ),
    );
  }

  /// Widget de error con icono fallback
  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Icon(errorIcon, color: Colors.grey[400], size: width * 0.5),
    );
  }
}

/// Variante CircleAvatar (más común)
/// 🛡️ MÓDULO 5: Para avatares de asesorados
class LazyCachedCircleAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final Color? backgroundColor;
  final IconData? errorIcon;

  const LazyCachedCircleAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 30,
    this.backgroundColor,
    this.errorIcon = Icons.person_outline,
  });

  @override
  Widget build(BuildContext context) {
    return LazyCachedImage(
      imageUrl: imageUrl,
      width: radius * 2,
      height: radius * 2,
      shape: BoxShape.circle,
      placeholderColor: backgroundColor ?? Colors.grey[300],
      errorIcon: errorIcon,
    );
  }
}

/// Variante RoundedRectangle (para tarjetas, etc.)
/// 🛡️ MÓDULO 5: Para imágenes de planes
class LazyCachedRoundedImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final Color? placeholderColor;

  const LazyCachedRoundedImage({
    super.key,
    required this.imageUrl,
    this.width = 100,
    this.height = 100,
    this.borderRadius = 8,
    this.placeholderColor,
  });

  @override
  Widget build(BuildContext context) {
    return LazyCachedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      shape: BoxShape.rectangle,
      borderRadius: BorderRadius.circular(borderRadius),
      placeholderColor: placeholderColor,
    );
  }
}
