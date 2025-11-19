import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'image_compression_service.dart';

/// Servicio para gestionar imágenes de perfil de asesorados
///
/// Responsabilidades:
/// - Seleccionar imágenes del dispositivo
/// - Guardar imágenes en directorio local
/// - Generar nombres únicos con estructura clara
/// - Eliminar imágenes antiguas
/// - Proporcionar rutas relativas para base de datos
class ImageService {
  static const String _profilePicturesDir =
      'assets/asesorados_profile_pictures';
  static const String _coachProfileDir = 'assets/coaches_profile_pictures';
  static final ImagePicker _imagePicker = ImagePicker();

  static Future<Directory> _getAppDocumentsDir() async {
    return getApplicationDocumentsDirectory();
  }

  /// Intenta resolver la raíz real del proyecto (donde vive assets).
  /// Si no se encuentra, retorna el directorio de documentos de la app.
  static Future<Directory> _getProjectRootDir() async {
    final candidates = <Directory>[];

    try {
      final current = Directory.current;
      candidates.add(current);
      candidates.add(current.parent);
    } catch (_) {}

    try {
      final executableDir = Directory(
        path.dirname(Platform.resolvedExecutable),
      );
      candidates.add(executableDir);
      candidates.add(executableDir.parent);
      candidates.add(executableDir.parent.parent);
    } catch (_) {}

    final appDocDir = await _getAppDocumentsDir();
    candidates.add(appDocDir);

    for (final dir in candidates) {
      if (dir.path.isEmpty) continue;
      final assetsDir = Directory(path.join(dir.path, 'assets'));
      if (await assetsDir.exists()) {
        return dir;
      }
    }

    return appDocDir;
  }

  static Future<Directory> _ensureProfilePicturesDirectory(
    String subDir,
  ) async {
    final normalizedSubDir = subDir;

    try {
      final rootDir = await _getProjectRootDir();
      final fullDir = Directory(path.join(rootDir.path, normalizedSubDir));

      if (!await fullDir.exists()) {
        await fullDir.create(recursive: true);
        if (kDebugMode) {
          debugPrint(
            '[ImageService] Directorio de imágenes creado: ${fullDir.path}',
          );
        }
      }

      return fullDir;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ImageService] No se pudo usar assets directamente: $e');
      }

      final appDocDir = await _getAppDocumentsDir();
      final fallbackSubDir = normalizedSubDir.replaceFirst('assets/', '');
      final fallbackDir = Directory(path.join(appDocDir.path, fallbackSubDir));

      if (!await fallbackDir.exists()) {
        await fallbackDir.create(recursive: true);
        if (kDebugMode) {
          debugPrint(
            '[ImageService] Directorio alterno creado: ${fallbackDir.path}',
          );
        }
      }

      return fallbackDir;
    }
  }

  /// Convierte una ruta almacenada en BD a ruta absoluta del sistema
  /// Formato BD: assets/asesorados_profile_pictures/asesorado_123.jpg
  /// Retorna la ruta absoluta completa en el directorio de proyecto
  static Future<String> _resolveAbsolutePath(String storagePath) async {
    if (storagePath.isEmpty) {
      return storagePath;
    }

    final normalizedStorage = path.normalize(storagePath);

    // Maneja rutas absolutas en cualquier plataforma (incluye C:\ en Windows)
    if (path.isAbsolute(normalizedStorage)) {
      return normalizedStorage;
    }

    final rootDir = await _getProjectRootDir();
    final primaryPath = path.normalize(path.join(rootDir.path, storagePath));
    final primaryFile = File(primaryPath);
    if (await primaryFile.exists()) {
      return primaryPath;
    }

    final appDocDir = await _getAppDocumentsDir();
    final fallbackPath =
        storagePath.startsWith('assets/')
            ? storagePath.replaceFirst('assets/', '')
            : storagePath;
    return path.normalize(path.join(appDocDir.path, fallbackPath));
  }

  static Future<String> _toStoragePath(String absolutePath) async {
    final rootDir = await _getProjectRootDir();
    final normalizedRoot = path.normalize(rootDir.path);
    final normalizedAbsolute = path.normalize(absolutePath);

    if (path.isWithin(normalizedRoot, normalizedAbsolute) ||
        normalizedAbsolute.startsWith(normalizedRoot)) {
      final relativePath = path.relative(
        normalizedAbsolute,
        from: normalizedRoot,
      );
      return relativePath.replaceAll('\\', '/');
    }

    return normalizedAbsolute;
  }

  /// Selecciona una imagen del dispositivo
  ///
  /// Retorna el archivo seleccionado o null si cancela
  static Future<XFile?> pickImageFromDevice() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Reducir tamaño sin perder calidad
        maxWidth: 1024,
        maxHeight: 1024,
      );
      return image;
    } catch (e) {
      throw Exception('Error al seleccionar imagen: $e');
    }
  }

  /// Guarda una imagen seleccionada en el directorio de documentos de la aplicación
  ///
  /// [imageFile] - Archivo de imagen seleccionado (XFile)
  /// [asesoradoId] - ID del asesorado para nombrar el archivo
  /// [oldImagePath] - Ruta de imagen anterior para eliminarla (opcional)
  ///
  /// Retorna la ruta ABSOLUTA del archivo guardado (para compatibilidad multi-plataforma)
  /// La imagen se comprime automáticamente antes de guardarse
  static Future<String> saveProfilePicture(
    XFile imageFile,
    int asesoradoId, {
    String? oldImagePath,
  }) async {
    try {
      final profilePicturesDir = await _ensureProfilePicturesDirectory(
        _profilePicturesDir,
      );

      // Generar nombre único: asesorado_123_1698345600000.jpg
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path).toLowerCase();
      final fileName = 'asesorado_${asesoradoId}_$timestamp$extension';

      // Ruta completa del archivo
      final fullPath = path.join(profilePicturesDir.path, fileName);

      // Convertir XFile a File para compresión
      final sourceFile = File(imageFile.path);

      // Comprimir imagen antes de guardarla
      final compressedFile = await ImageCompressionService.compressImage(
        imageFile: sourceFile,
        targetMaxWidth: 500,
        targetMaxHeight: 500,
        quality: 80,
      );

      // Copiar archivo comprimido al directorio de documentos
      await compressedFile.copy(fullPath);

      if (kDebugMode) {
        debugPrint('[ImageService] Imagen guardada (comprimida): $fullPath');
      }

      // Limpia el archivo temporal comprimido si es diferente al original
      if (compressedFile.path != sourceFile.path) {
        try {
          await compressedFile.delete();
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              '[ImageService] Error al limpiar archivo temporal comprimido: $e',
            );
          }
        }
      }

      // Eliminar imagen anterior si existe
      if (oldImagePath != null && oldImagePath.isNotEmpty) {
        await deleteProfilePicture(oldImagePath);
      }

      return await _toStoragePath(fullPath);
    } catch (e) {
      throw Exception('Error al guardar imagen: $e');
    }
  }

  /// Obtiene el archivo de imagen para mostrar
  ///
  /// [relativePath] - Ruta relativa guardada en BD
  ///
  /// Retorna File si existe, null si no
  static Future<File?> getProfilePicture(String? relativePath) async {
    if (relativePath == null || relativePath.isEmpty) {
      return null;
    }

    try {
      final absolutePath = await _resolveAbsolutePath(relativePath);
      final file = File(absolutePath);

      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      // Error logging en silencio - usar framework de logging en producción
      return null;
    }
  }

  /// Elimina una imagen de perfil del dispositivo
  ///
  /// [relativePath] - Ruta relativa guardada en BD
  static Future<void> deleteProfilePicture(String? relativePath) async {
    if (relativePath == null || relativePath.isEmpty) {
      return;
    }

    try {
      final absolutePath = await _resolveAbsolutePath(relativePath);
      final file = File(absolutePath);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Error logging en silencio - usar framework de logging en producción
    }
  }

  /// Limpia imágenes antiguas de un asesorado
  /// Útil para no acumular imágenes sin usar
  ///
  /// [asesoradoId] - ID del asesorado
  /// [keepLatest] - Mantener la imagen más reciente (true)
  static Future<void> cleanOldProfilePictures(
    int asesoradoId, {
    bool keepLatest = true,
  }) async {
    try {
      final profilePicturesDir = await _ensureProfilePicturesDirectory(
        _profilePicturesDir,
      );

      if (!await profilePicturesDir.exists()) {
        return;
      }

      // Listar todos los archivos de este asesorado
      final files =
          profilePicturesDir
              .listSync()
              .whereType<File>()
              .where(
                (f) => path
                    .basename(f.path)
                    .startsWith('asesorado_${asesoradoId}_'),
              )
              .toList();

      if (files.isEmpty) return;

      // Ordenar por timestamp descendente (más recientes primero)
      files.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      );

      // Si keepLatest es true, mantener el primero
      final filesToDelete = keepLatest ? files.skip(1).toList() : files;

      for (var file in filesToDelete) {
        try {
          await file.delete();
          if (kDebugMode) {
            debugPrint('[ImageService] Imagen eliminada: ${file.path}');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[ImageService] Error eliminando imagen: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ImageService] Error limpiando imágenes antiguas: $e');
      }
    }
  }

  /// Valida si una ruta de imagen existe
  static Future<bool> validateProfilePicture(String? relativePath) async {
    final file = await getProfilePicture(relativePath);
    return file != null;
  }

  // --- Coach Profile Methods ---

  /// Guarda una imagen de perfil para un coach
  /// Similar a saveProfilePicture pero para coaches
  /// Retorna la ruta ABSOLUTA del archivo guardado
  /// La imagen se comprime automáticamente antes de guardarse
  static Future<String> saveCoachProfilePicture(
    File imageFile,
    int coachId, {
    String? oldImagePath,
  }) async {
    try {
      final coachPicturesDir = await _ensureProfilePicturesDirectory(
        _coachProfileDir,
      );

      // Generar nombre único: coach_123_1698345600000.jpg
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path).toLowerCase();
      final fileName = 'coach_${coachId}_$timestamp$extension';

      // Ruta completa del archivo
      final fullPath = path.join(coachPicturesDir.path, fileName);

      // Comprimir imagen antes de guardarla
      final compressedFile = await ImageCompressionService.compressImage(
        imageFile: imageFile,
        targetMaxWidth: 500,
        targetMaxHeight: 500,
        quality: 80,
      );

      // Copiar archivo comprimido a directorio de documentos de la aplicación
      await compressedFile.copy(fullPath);

      if (kDebugMode) {
        debugPrint(
          '[ImageService] Foto de coach guardada (comprimida): $fullPath',
        );
      }

      // Limpia el archivo temporal comprimido si es diferente al original
      if (compressedFile.path != imageFile.path) {
        try {
          await compressedFile.delete();
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              '[ImageService] Error al limpiar archivo temporal comprimido: $e',
            );
          }
        }
      }

      // Eliminar imagen anterior si existe
      if (oldImagePath != null && oldImagePath.isNotEmpty) {
        await deleteProfilePicture(oldImagePath);
      }

      return await _toStoragePath(fullPath);
    } catch (e) {
      throw Exception('Error al guardar foto de coach: $e');
    }
  }

  /// Obtiene la foto de perfil de un coach
  static Future<File?> getCoachProfilePicture(String? relativePath) async {
    return getProfilePicture(relativePath);
  }

  // --- End Coach Profile Methods ---
}
