import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:image/image.dart' as img;
import 'dart:developer' as developer;

/// ImageCompressionService - Comprime imágenes de usuario/coach
/// Reduce tamaño en disco/transferencia sin perder calidad apreciable
/// Usa dimensión máxima 500x500px, JPEG quality 80%
class ImageCompressionService {
  static const int maxWidth = 500;
  static const int maxHeight = 500;
  static const int jpegQuality = 80;

  /// Comprime una imagen desde archivo
  /// Retorna File con imagen comprimida
  /// Guarda con mismo nombre original en directorio temp
  static Future<File> compressImage({
    required File imageFile,
    int targetMaxWidth = maxWidth,
    int targetMaxHeight = maxHeight,
    int quality = jpegQuality,
  }) async {
    try {
      // Leer imagen original
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        if (kDebugMode) {
          developer.log(
            '[ImageCompression] No se pudo decodificar imagen',
            name: 'ImageCompressionService',
          );
        }
        return imageFile; // Retornar original si hay error
      }

      // Redimensionar si es más grande que target
      if (image.width > targetMaxWidth || image.height > targetMaxHeight) {
        final aspectRatio = image.width / image.height;
        late int newWidth;
        late int newHeight;

        if (aspectRatio > 1) {
          // Landscape
          newWidth = targetMaxWidth;
          newHeight = (targetMaxWidth / aspectRatio).toInt();
        } else {
          // Portrait
          newHeight = targetMaxHeight;
          newWidth = (targetMaxHeight * aspectRatio).toInt();
        }

        image = img.copyResize(
          image,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );

        if (kDebugMode) {
          developer.log(
            '[ImageCompression] Redimensionada: ${image.width}x${image.height}',
            name: 'ImageCompressionService',
          );
        }
      }

      // Convertir a JPEG con calidad especificada
      final compressedBytes = img.encodeJpg(image, quality: quality);

      // Guardar en archivo temporal
      final compressedFile = File('${imageFile.path}.compressed.jpg');
      await compressedFile.writeAsBytes(compressedBytes);

      final originalSize = bytes.length;
      final compressedSize = compressedBytes.length;
      final reduction = ((originalSize - compressedSize) / originalSize * 100)
          .toStringAsFixed(1);

      if (kDebugMode) {
        developer.log(
          '[ImageCompression] Compresión: ${originalSize}B → ${compressedSize}B (-$reduction%)',
          name: 'ImageCompressionService',
        );
      }

      return compressedFile;
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          '[ImageCompression] Error: $e',
          name: 'ImageCompressionService',
          error: e,
        );
      }
      return imageFile; // Retornar original si hay error
    }
  }

  /// Comprime múltiples imágenes
  static Future<List<File>> compressImages({
    required List<File> imageFiles,
    int targetMaxWidth = maxWidth,
    int targetMaxHeight = maxHeight,
    int quality = jpegQuality,
  }) async {
    final compressed = <File>[];
    for (final file in imageFiles) {
      try {
        final result = await compressImage(
          imageFile: file,
          targetMaxWidth: targetMaxWidth,
          targetMaxHeight: targetMaxHeight,
          quality: quality,
        );
        compressed.add(result);
      } catch (e) {
        if (kDebugMode) {
          developer.log(
            '[ImageCompression] Error en batch: $e',
            name: 'ImageCompressionService',
          );
        }
        compressed.add(file);
      }
    }
    return compressed;
  }

  /// Obtiene info de tamaño de imagen sin decodificar completamente
  static Future<ImageDimensions> getImageDimensions(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image != null) {
        return ImageDimensions(
          width: image.width,
          height: image.height,
          fileSize: bytes.length,
        );
      }
      return ImageDimensions(width: 0, height: 0, fileSize: bytes.length);
    } catch (e) {
      return ImageDimensions(width: 0, height: 0, fileSize: 0);
    }
  }
}

/// Clase para retornar dimensiones de imagen
class ImageDimensions {
  final int width;
  final int height;
  final int fileSize;

  ImageDimensions({
    required this.width,
    required this.height,
    required this.fileSize,
  });

  @override
  String toString() => 'Image $width x$height ($fileSize B)';
}
