import 'package:coachhub/services/db_connection.dart';
import 'package:coachhub/services/image_cache_service.dart';
import 'package:coachhub/services/image_service.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show kDebugMode;

/// ImagePreloadService - Precarga imágenes en background
/// Al iniciar la app, precarga fotos del coach + primeros 10 asesorados
/// Mejora experiencia inicial (no hay "loading" de fotos)
class ImagePreloadService {
  static final ImagePreloadService _instance = ImagePreloadService._internal();

  factory ImagePreloadService() {
    return _instance;
  }

  ImagePreloadService._internal();

  final _imageCache = ImageCacheService();
  bool _isPreloading = false;

  /// Obtiene instancia singleton
  static ImagePreloadService get instance => _instance;

  /// Precarga fotos del coach + primeros 10 asesorados
  /// Se ejecuta en background sin bloquear UI
  /// Llamar desde main() o después del login
  Future<void> preloadInitialImages({String? coachPhotoUrl}) async {
    if (_isPreloading) {
      if (kDebugMode) {
        developer.log(
          '[ImagePreload] Precarga ya en progreso, saltando',
          name: 'ImagePreloadService',
        );
      }
      return;
    }

    _isPreloading = true;

    try {
      if (kDebugMode) {
        developer.log(
          '[ImagePreload] Iniciando precarga de imágenes iniciales',
          name: 'ImagePreloadService',
        );
      }

      // 1. Precargar foto del coach
      if (coachPhotoUrl != null && coachPhotoUrl.isNotEmpty) {
        try {
          final coachPhoto = await ImageService.getProfilePicture(
            coachPhotoUrl,
          );
          if (coachPhoto != null) {
            await _imageCache.getImageWithCache(coachPhoto.path);
            if (kDebugMode) {
              developer.log(
                '[ImagePreload] Foto coach precargada',
                name: 'ImagePreloadService',
              );
            }
          }
        } catch (e) {
          if (kDebugMode) {
            developer.log(
              '[ImagePreload] Error precargando foto coach: $e',
              name: 'ImagePreloadService',
            );
          }
        }
      }

      // 2. Precargar primeros 10 asesorados
      try {
        final db = DatabaseConnection.instance;
        final results = await db.query('''
          SELECT id, avatar_url FROM asesorados 
          WHERE status = 'activo' 
          ORDER BY nombre 
          LIMIT 10
          ''');

        int preloadedCount = 0;
        for (final row in results) {
          try {
            final avatarUrl = row.fields['avatar_url'] as String?;
            if (avatarUrl != null && avatarUrl.isNotEmpty) {
              final photo = await ImageService.getProfilePicture(avatarUrl);
              if (photo != null) {
                await _imageCache.getImageWithCache(photo.path);
                preloadedCount++;
              }
            }
          } catch (e) {
            // Continuar con siguiente asesorado en caso de error
            if (kDebugMode) {
              developer.log(
                '[ImagePreload] Error precargando asesorado: $e',
                name: 'ImagePreloadService',
              );
            }
          }
        }

        if (kDebugMode) {
          developer.log(
            '[ImagePreload] Precargadas $preloadedCount fotos de asesorados',
            name: 'ImagePreloadService',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          developer.log(
            '[ImagePreload] Error en precarga de asesorados: $e',
            name: 'ImagePreloadService',
            error: e,
          );
        }
      }

      if (kDebugMode) {
        final stats = _imageCache.getCacheStats();
        developer.log(
          '[ImagePreload] Precarga completada. Cache: ${stats['items']} items, ${stats['size']}MB usados',
          name: 'ImagePreloadService',
        );
      }
    } finally {
      _isPreloading = false;
    }
  }

  /// Precarga imágenes para un asesorado específico
  /// Útil cuando se abre ficha de asesorado
  Future<void> preloadAsesoradoImages(int asesoradoId) async {
    try {
      final db = DatabaseConnection.instance;
      final results = await db.query(
        'SELECT avatar_url FROM asesorados WHERE id = ?',
        [asesoradoId],
      );

      if (results.isNotEmpty) {
        final avatarUrl = results.first.fields['avatar_url'] as String?;
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          final photo = await ImageService.getProfilePicture(avatarUrl);
          if (photo != null) {
            await _imageCache.getImageWithCache(photo.path);
            if (kDebugMode) {
              developer.log(
                '[ImagePreload] Imagen asesorado $asesoradoId precargada',
                name: 'ImagePreloadService',
              );
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          '[ImagePreload] Error precargando asesorado $asesoradoId: $e',
          name: 'ImagePreloadService',
        );
      }
    }
  }

  /// Precarga imágenes para una lista de asesorados
  /// Útil en lazy pagination
  Future<void> preloadMultipleAsesoradosImages(List<int> asesoradoIds) async {
    for (final id in asesoradoIds) {
      await preloadAsesoradoImages(id);
    }
  }

  /// Obtiene stats del caché
  Map<String, dynamic> getCacheStats() {
    return _imageCache.getCacheStats();
  }

  /// Limpia el caché
  void clearCache() {
    _imageCache.clearCache();
    if (kDebugMode) {
      developer.log(
        '[ImagePreload] Caché limpiado',
        name: 'ImagePreloadService',
      );
    }
  }

  /// Getter para estado de precarga
  bool get isPreloading => _isPreloading;
}
