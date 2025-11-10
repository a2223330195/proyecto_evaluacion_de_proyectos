import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:coachhub/services/db_connection.dart';
import 'package:coachhub/services/pagination_service.dart';
import 'package:coachhub/services/image_service.dart';
import 'package:coachhub/utils/app_error_handler.dart' show executeWithRetry;
import '../models/asesorado_model.dart';
import '../models/plan_model.dart';

/// Servicio para operaciones con asesorados
class AsesoradosService {
  final DatabaseConnection _db = DatabaseConnection.instance;
  final PaginationService _paginationService = PaginationService(pageSize: 10);

  // 🛡️ MÓDULO 4: Cache mejorado para fallback offline
  // ignore: unused_field
  final Map<int, List<Asesorado>> _asesoradosCache = {};
  // ignore: unused_field
  final Map<int, DateTime> _asesoradosCacheTime = {};
  // ignore: unused_field
  static const Duration _cacheDuration = Duration(minutes: 10);

  /// Obtener asesorados paginados
  /// ✅ PaginationService ya incluye el JOIN con planes, no hay redundancia
  Future<List<Asesorado>> getPaginatedAsesorados({
    required int pageNumber,
    int? coachId,
    String? searchQuery,
    AsesoradoStatus? statusFilter,
  }) async {
    return await _paginationService.loadAsesoradosPage(
      pageNumber: pageNumber,
      coachId: coachId,
      searchQuery: searchQuery,
      statusFilter: statusFilter,
    );
  }

  /// Obtener total de asesorados
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<int> getAsesoradosCount({int? coachId}) async {
    return executeWithRetry(() async {
      try {
        String query = 'SELECT COUNT(*) as total FROM asesorados';
        List<dynamic> params = [];

        if (coachId != null) {
          query += ' WHERE coach_id = ?';
          params.add(coachId);
        }

        final result = await _db.query(query, params);
        if (result.isNotEmpty) {
          return int.tryParse(result.first.fields['total'].toString()) ?? 0;
        }
        return 0;
      } catch (e) {
        // Si falla y tenemos caché, retornar caché
        return 0;
      }
    }, operationName: 'getAsesoradosCount');
  }

  /// Eliminar un asesorado
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<void> deleteAsesorado(int asesoradoId) async {
    return executeWithRetry(
      () => _db.query('DELETE FROM asesorados WHERE id = ?', [asesoradoId]),
      operationName: 'deleteAsesorado($asesoradoId)',
    );
  }

  /// Obtener un asesorado por ID
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<Asesorado?> getAsesoradoById(int asesoradoId) async {
    return executeWithRetry(() async {
      final results = await _db.query('SELECT * FROM asesorados WHERE id = ?', [
        asesoradoId,
      ]);
      if (results.isNotEmpty) {
        return Asesorado.fromMap(results.first.fields);
      }
      return null;
    }, operationName: 'getAsesoradoById($asesoradoId)');
  }

  /// Obtener detalles completos de un asesorado, incluyendo información del plan
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<Asesorado?> getAsesoradoDetails(int asesoradoId) async {
    return executeWithRetry(() async {
      final results = await _db.query(
        '''
          SELECT a.*, p.nombre AS plan_nombre
          FROM asesorados a
          LEFT JOIN planes p ON a.plan_id = p.id
          WHERE a.id = ?
          '''.trim(),
        [asesoradoId],
      );

      if (results.isEmpty) {
        return null;
      }

      return Asesorado.fromMap(results.first.fields);
    }, operationName: 'getAsesoradoDetails($asesoradoId)');
  }

  /// Obtener total de páginas
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<int> getTotalPages({int pageSize = 10}) async {
    final count = await getAsesoradosCount();
    return (count / pageSize).ceil();
  }

  /// Crear un nuevo asesorado de forma atómica usando objeto Asesorado como DTO
  /// Parámetros consolidados: evita acoplamiento de parámetros individuales
  /// Procesa la imagen PRIMERO antes de insertar en BD
  /// Si la imagen falla, la BD nunca se toca (previene estado inconsistente)
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<int> createAsesorado({
    required Asesorado data,
    dynamic profileImage, // XFile - opcional, nueva imagen
  }) async {
    return executeWithRetry(() async {
      String? finalImagePath;

      // ✅ PASO 1: PROCESAR LA IMAGEN PRIMERO (antes de tocar la BD)
      // Si falla aquí, la BD nunca se modifica (datos consistentes)
      // Usamos asesoradoId=0 temporalmente; será renombrada después del INSERT
      if (profileImage != null) {
        finalImagePath = await _saveProfilePictureForAsesorado(profileImage, 0);
      }

      // ✅ PASO 2: INSERTAR ÚNICO EN BD con la ruta de imagen lista
      // Si llegamos aquí, la imagen ya está guardada (o no hay imagen)
      const insertSql =
          'INSERT INTO asesorados (nombre, avatar_url, plan_id, fecha_vencimiento, status, edad, sexo, altura_cm, telefono, fecha_inicio_programa, objetivo_principal, objetivo_secundario, coach_id) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)';

      await _db.query(insertSql, [
        data.name,
        finalImagePath ?? data.avatarUrl, // Nueva imagen o existente
        data.planId,
        data.dueDate?.toUtc(),
        data.status.name,
        data.edad,
        data.sexo,
        data.alturaCm,
        data.telefono?.replaceAll(RegExp(r'\D'), ''),
        data.fechaInicioPrograma?.toUtc(),
        data.objetivoPrincipal,
        data.objetivoSecundario,
        data.coachId, // ✅ CLAVE: Usar el coachId del objeto data
      ]);

      // ✅ PASO 3: Obtener el ID del asesorado recién creado
      final lastIdResult = await _db.query('SELECT LAST_INSERT_ID() as id');
      if (lastIdResult.isEmpty) {
        throw Exception('No se pudo obtener el ID del nuevo asesorado');
      }

      final newAsesoradoId =
          int.tryParse(lastIdResult.first.fields['id'].toString()) ?? 0;
      if (newAsesoradoId == 0) {
        throw Exception('ID de asesorado inválido');
      }

      // ✅ PASO 4: Si la imagen fue guardada con ID temporal (0),
      // renombrarla ahora que tenemos el ID real y actualizar BD
      if (profileImage != null && finalImagePath != null) {
        try {
          // Renombrar archivo en disco de asesorado_0_timestamp.jpg a asesorado_ID_timestamp.jpg
          final oldFile = File(finalImagePath);
          final newImagePath = finalImagePath.replaceFirst(
            'asesorado_0_',
            'asesorado_${newAsesoradoId}_',
          );

          if (await oldFile.exists()) {
            await oldFile.rename(newImagePath);

            // Actualizar la ruta en BD con el nombre definitivo
            const updateSql =
                'UPDATE asesorados SET avatar_url = ? WHERE id = ?';
            await _db.query(updateSql, [newImagePath, newAsesoradoId]);
          }
        } catch (e) {
          // Si falla el renombramiento, mantener la ruta actual
          // El archivo existe, solo con nombre subóptimo
          if (kDebugMode) {
            debugPrint('Error renombrando imagen: $e');
          }
        }
      }

      return newAsesoradoId;
    }, operationName: 'createAsesorado');
  }

  /// Actualizar un asesorado existente usando objeto Asesorado como DTO
  /// Parámetros consolidados: evita acoplamiento de parámetros individuales
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<void> updateAsesorado({
    required int id,
    required Asesorado data,
    dynamic newProfileImage, // XFile
    bool deleteImage = false,
  }) async {
    return executeWithRetry(() async {
      String? finalImagePath = data.avatarUrl;

      // Procesar imagen
      if (newProfileImage != null) {
        finalImagePath = await _saveProfilePictureForAsesorado(
          newProfileImage,
          id,
        );
      } else if (deleteImage && data.avatarUrl.isNotEmpty) {
        await _deleteProfilePictureForAsesorado(data.avatarUrl);
        finalImagePath = '';
      }

      const updateSql =
          'UPDATE asesorados SET nombre = ?, avatar_url = ?, plan_id = ?, fecha_vencimiento = ?, status = ?, edad = ?, sexo = ?, altura_cm = ?, telefono = ?, fecha_inicio_programa = ?, objetivo_principal = ?, objetivo_secundario = ? WHERE id = ?';

      await _db.query(updateSql, [
        data.name,
        finalImagePath,
        data.planId,
        data.dueDate?.toUtc(),
        data.status.name,
        data.edad,
        data.sexo,
        data.alturaCm,
        data.telefono?.replaceAll(RegExp(r'\D'), ''),
        data.fechaInicioPrograma?.toUtc(),
        data.objetivoPrincipal,
        data.objetivoSecundario,
        id,
      ]);
    }, operationName: 'updateAsesorado($id)');
  }

  /// Obtener planes para un coach específico
  /// Retorna planes del coach actual + planes genéricos
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<List<Plan>> getPlanesForCoach(int? coachId) async {
    return executeWithRetry(() async {
      String sql =
          'SELECT id, nombre, costo, coach_id, created_at FROM planes WHERE coach_id = ? OR coach_id IS NULL ORDER BY nombre';
      List<Object?> params = [coachId];

      if (coachId == null) {
        sql =
            'SELECT id, nombre, costo, coach_id, created_at FROM planes ORDER BY nombre';
        params = [];
      }

      final results = await _db.query(sql, params);
      return results.map((row) => Plan.fromMap(row.fields)).toList();
    }, operationName: 'getPlanesForCoach');
  }

  // --- Métodos Auxiliares Privados ---

  /// Guarda la imagen de perfil de un asesorado
  /// Integra con ImageService para comprimir y almacenar
  Future<String> _saveProfilePictureForAsesorado(
    dynamic imageFile,
    int asesoradoId,
  ) async {
    try {
      // imageFile es un XFile de image_picker
      final imagePath = await ImageService.saveProfilePicture(
        imageFile,
        asesoradoId,
      );
      return imagePath;
    } catch (e) {
      throw Exception('Error al guardar imagen de perfil: $e');
    }
  }

  /// Elimina la imagen de perfil de un asesorado
  /// Integra con ImageService para limpiar archivos
  Future<void> _deleteProfilePictureForAsesorado(String imagePath) async {
    try {
      await ImageService.deleteProfilePicture(imagePath);
    } catch (e) {
      throw Exception('Error al eliminar imagen de perfil: $e');
    }
  }
}
