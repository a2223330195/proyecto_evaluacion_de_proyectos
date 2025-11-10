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
  static const String _profilePicturesDir = 'asesorados_profile_pictures';
  static const String _coachProfileDir = 'coaches_profile_pictures';
  static final ImagePicker _imagePicker = ImagePicker();

  /// Obtiene el directorio de documentos de la aplicación
  /// En Windows: AppData\Roaming\coachhub\
  /// En Android: /data/user/0/com.example.coachhub/app_flutter/
  /// En iOS: /var/mobile/Containers/Data/Application/.../Documents/
  static Future<Directory> _getAppDocumentsDir() async {
    return await getApplicationDocumentsDirectory();
  }

  /// Asegura que exista el subdirectorio indicado dentro del directorio de documentos.
  static Future<Directory> _ensureProfilePicturesDirectory(
    String subDir,
  ) async {
    final appDocDir = await _getAppDocumentsDir();
    final fullDir = Directory(path.join(appDocDir.path, subDir));

    if (!await fullDir.exists()) {
      await fullDir.create(recursive: true);
      if (kDebugMode) {
        debugPrint(
          '[ImageService] Directorio de imágenes creado: ${fullDir.path}',
        );
      }
    }

    return fullDir;
  }

  /// Convierte una ruta almacenada en BD a ruta absoluta del sistema
  /// Formato BD anterior: assets/asesorados_profile_pictures/asesorado_123.jpg
  /// Formato nuevo: directo a ruta absoluta (se usa directamente)
  static Future<String> _resolveAbsolutePath(String storagePath) async {
    // Si ya es una ruta absoluta (comienza con /), usarla directamente
    if (storagePath.startsWith('/')) {
      return storagePath;
    }

    // Si es una ruta relativa de assets (legacy), convertir
    if (storagePath.startsWith('assets/')) {
      final appDocDir = await _getAppDocumentsDir();
      final fileName = storagePath.replaceFirst(
        'assets/asesorados_profile_pictures/',
        '',
      );
      return path.join(appDocDir.path, _profilePicturesDir, fileName);
    }

    // Asumir que es relativa al directorio de documentos
    final appDocDir = await _getAppDocumentsDir();
    return path.join(appDocDir.path, storagePath);
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

      // Retornar ruta ABSOLUTA para compatibilidad multi-plataforma
      return fullPath;
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

      // Retornar ruta ABSOLUTA
      return fullPath;
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
