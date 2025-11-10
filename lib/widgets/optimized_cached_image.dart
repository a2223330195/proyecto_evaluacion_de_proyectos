import 'dart:io';
import 'package:flutter/material.dart';
import 'package:coachhub/services/image_cache_service.dart';

/// Widget optimizado para mostrar imágenes con caching y lazy loading
/// Reduce reconstrucciones y mejora performance
class OptimizedCachedImage extends StatefulWidget {
  final String? imagePath;
  final double width;
  final double height;
  final BoxShape shape;
  final Color? placeholderColor;
  final IconData? placeholderIcon;
  final bool isCircle;

  const OptimizedCachedImage({
    super.key,
    required this.imagePath,
    this.width = 100,
    this.height = 100,
    this.shape = BoxShape.rectangle,
    this.placeholderColor,
    this.placeholderIcon,
    this.isCircle = false,
  });

  @override
  State<OptimizedCachedImage> createState() => _OptimizedCachedImageState();
}

class _OptimizedCachedImageState extends State<OptimizedCachedImage> {
  final ImageCacheService _cacheService = ImageCacheService();
  late Future<File?> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _cacheService.getImageWithCache(widget.imagePath);
  }

  @override
  void didUpdateWidget(OptimizedCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si la ruta cambió, recargar
    if (oldWidget.imagePath != widget.imagePath) {
      _imageFuture = _cacheService.getImageWithCache(widget.imagePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholder();
        }

        if (snapshot.hasData && snapshot.data != null) {
          return _buildImageContainer(FileImage(snapshot.data!));
        }

        return _buildPlaceholder();
      },
    );
  }

  Widget _buildImageContainer(ImageProvider imageProvider) {
    if (widget.isCircle) {
      return CircleAvatar(
        radius: widget.width / 2,
        backgroundImage: imageProvider,
      );
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        shape: widget.shape,
        image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildPlaceholder() {
    if (widget.isCircle) {
      return CircleAvatar(
        radius: widget.width / 2,
        backgroundColor: widget.placeholderColor ?? Colors.grey[300],
        child: Icon(
          widget.placeholderIcon ?? Icons.person,
          color: Colors.grey[600],
        ),
      );
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        shape: widget.shape,
        color: widget.placeholderColor ?? Colors.grey[300],
      ),
      child: Icon(
        widget.placeholderIcon ?? Icons.image,
        color: Colors.grey[600],
      ),
    );
  }
}

/// Variante para CircleAvatar (más común)
class OptimizedCachedCircleAvatar extends StatelessWidget {
  final String? imagePath;
  final double radius;
  final Color? backgroundColor;
  final IconData? placeholderIcon;

  const OptimizedCachedCircleAvatar({
    super.key,
    required this.imagePath,
    this.radius = 20,
    this.backgroundColor,
    this.placeholderIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    return OptimizedCachedImage(
      imagePath: imagePath,
      width: radius * 2,
      height: radius * 2,
      shape: BoxShape.circle,
      placeholderColor: backgroundColor,
      placeholderIcon: placeholderIcon,
      isCircle: true,
    );
  }
}
