import 'dart:io';
import 'package:flutter/foundation.dart';

/// Servicio de caché en memoria para imágenes
/// Reduce acceso a disco y mejora performance
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();

  factory ImageCacheService() {
    return _instance;
  }

  ImageCacheService._internal();

  // Caché en memoria: path -> File
  final Map<String, File> _memoryCache = {};

  // Tracking de size del cache
  final Map<String, int> _fileSizes = {};
  static const int maxCacheSize = 50 * 1024 * 1024; // 50 MB
  int _currentCacheSize = 0;

  /// Obtiene imagen del caché o disco
  /// Si no está en caché, la carga y cachea
  Future<File?> getImageWithCache(String? filePath) async {
    if (filePath == null || filePath.isEmpty) {
      return null;
    }

    // Verificar si está en caché
    if (_memoryCache.containsKey(filePath)) {
      if (kDebugMode) {
        print('[ImageCacheService] Cache HIT: $filePath');
      }
      return _memoryCache[filePath];
    }

    // Cargar del disco
    try {
      final file = File(filePath);
      if (await file.exists()) {
        // Obtener tamaño del archivo
        final size = await file.length();

        // Verificar si hay espacio en caché
        await _addToCache(filePath, file, size);

        if (kDebugMode) {
          print('[ImageCacheService] Cache MISS - Loaded from disk: $filePath');
        }
        return file;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ImageCacheService] Error loading image: $e');
      }
    }

    return null;
  }

  /// Agrega imagen al caché y gestiona límite de memoria
  Future<void> _addToCache(String path, File file, int size) async {
    // Si agregar esta imagen excede el límite, limpiar caché
    if (_currentCacheSize + size > maxCacheSize) {
      await _evictOldestEntries();
    }

    _memoryCache[path] = file;
    _fileSizes[path] = size;
    _currentCacheSize += size;

    if (kDebugMode) {
      print(
        '[ImageCacheService] Cache size: ${_currentCacheSize ~/ (1024 * 1024)} MB',
      );
    }
  }

  /// Elimina entradas más antiguas del caché (LRU-style)
  Future<void> _evictOldestEntries() async {
    final entriesToRemove = (_memoryCache.length * 0.3).ceil(); // Remover 30%

    final entries = _memoryCache.entries.toList();
    for (int i = 0; i < entriesToRemove && i < entries.length; i++) {
      final entry = entries[i];
      _currentCacheSize -= (_fileSizes[entry.key] ?? 0);
      _memoryCache.remove(entry.key);
      _fileSizes.remove(entry.key);

      if (kDebugMode) {
        print('[ImageCacheService] Evicted: ${entry.key}');
      }
    }
  }

  /// Limpia todo el caché
  void clearCache() {
    _memoryCache.clear();
    _fileSizes.clear();
    _currentCacheSize = 0;

    if (kDebugMode) {
      print('[ImageCacheService] Cache cleared');
    }
  }

  /// Obtiene estadísticas del caché
  Map<String, dynamic> getCacheStats() {
    return {
      'totalItems': _memoryCache.length,
      'totalSize':
          '${(_currentCacheSize / (1024 * 1024)).toStringAsFixed(2)} MB',
      'maxSize': '${(maxCacheSize / (1024 * 1024)).toStringAsFixed(2)} MB',
      'percentUsed': ((_currentCacheSize / maxCacheSize) * 100).toStringAsFixed(
        1,
      ),
    };
  }

  /// Precarga imágenes importantes
  /// Útil para precargar fotos de coaches al iniciar
  Future<void> preloadImages(List<String?> imagePaths) async {
    for (final path in imagePaths) {
      if (path != null && path.isNotEmpty) {
        await getImageWithCache(path);
      }
    }
  }
}
