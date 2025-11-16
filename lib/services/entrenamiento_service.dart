// lib/services/entrenamiento_service.dart
// Servicio consolidado que combina la lógica de tres servicios antiguos:
// - RutinasService (gestión de rutinas y ejercicios)
// - EntrenamientosService (obtención de entrenamientos recientes)
// - RoutineAssignmentService (creación y gestión de asignaciones)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mysql1/mysql1.dart';
import 'package:coachhub/utils/app_error_handler.dart' show executeWithRetry;

import 'package:coachhub/models/asignacion_model.dart';
import 'package:coachhub/models/ejercicio_model.dart';
import 'package:coachhub/models/ejercicio_maestro_model.dart';
import 'package:coachhub/models/log_ejercicio_model.dart';
import 'package:coachhub/models/log_serie_model.dart';
import 'package:coachhub/models/rutina_batch_detalle_model.dart';
import 'db_connection.dart';

/// Estructura de datos para representar la asignación de una rutina a un día específico
class RoutineDayAssignment {
  final DateTime date;
  final TimeOfDay? time;
  final bool enabled;
  final String? notes;

  const RoutineDayAssignment({
    required this.date,
    this.time,
    this.enabled = true,
    this.notes,
  });

  RoutineDayAssignment copyWith({
    DateTime? date,
    TimeOfDay? time,
    bool? enabled,
    String? notes,
  }) {
    return RoutineDayAssignment(
      date: date ?? this.date,
      time: time ?? this.time,
      enabled: enabled ?? this.enabled,
      notes: notes ?? this.notes,
    );
  }
}

/// Servicio consolidado para gestión de entrenamientos, rutinas y asignaciones
class EntrenamientoService {
  EntrenamientoService();

  final DatabaseConnection _db = DatabaseConnection.instance;
  final _dateFormatter = DateFormat('yyyy-MM-dd');

  // ============================================================================
  // MÉTODOS DE ASIGNACIONES Y DETALLES (anteriormente en RutinasService)
  // ============================================================================

  /// Obtiene los detalles de una asignación específica
  /// Retorna el modelo Asignacion con todos sus campos
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<Asignacion?> getAsignacionDetails(int asignacionId) async {
    return executeWithRetry(() async {
      final results = await _db.query(
        '''
          SELECT 
            aa.id, aa.asesorado_id, aa.plantilla_id, aa.batch_id, aa.fecha_asignada, 
            aa.hora_asignada, aa.status, aa.notes, aa.feedback_asesorado,
            a.nombre AS asesorado_nombre, a.avatar_url AS asesorado_avatar_url,
            r.nombre AS rutina_nombre
          FROM asignaciones_agenda aa
          LEFT JOIN asesorados a ON aa.asesorado_id = a.id
          LEFT JOIN rutinas_plantillas r ON aa.plantilla_id = r.id
          WHERE aa.id = ?
          ''',
        [asignacionId],
      );

      if (results.isEmpty) {
        return null;
      }

      return Asignacion.fromMap(results.first.fields);
    }, operationName: 'getAsignacionDetails($asignacionId)');
  }

  /// Obtiene todos los ejercicios de una plantilla de rutina con sus detalles maestros
  /// Ordenados por el campo "orden" para mantener el orden correcto
  /// Utiliza JOIN con ejercicios_maestro para obtener nombre, video_url, etc.
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<List<Ejercicio>> getEjerciciosDePlantilla(int plantillaId) async {
    return executeWithRetry(() async {
      const sql = '''
          SELECT 
            e.id, e.plantilla_id, e.ejercicio_maestro_id, e.series, e.repeticiones, 
            e.indicador_carga, e.notas, e.orden, e.descanso,
            em.nombre, em.musculo_principal, em.equipamiento, em.video_url, em.fuente
          FROM 
            ejercicios e
          JOIN 
            ejercicios_maestro em ON e.ejercicio_maestro_id = em.id
          WHERE 
            e.plantilla_id = ?
          ORDER BY 
            e.orden ASC
        ''';

      final results = await _db.query(sql, [plantillaId]);
      return results.map((row) => Ejercicio.fromMap(row.fields)).toList();
    }, operationName: 'getEjerciciosDePlantilla($plantillaId)');
  }

  /// Obtiene los detalles completos de una asignación incluyendo todos los ejercicios
  /// Retorna un map con: asignacion, plantilla_nombre, ejercicios
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<Map<String, dynamic>?> getDetalleAsignacionConEjercicios(
    int asignacionId,
  ) async {
    return executeWithRetry(() async {
      // Obtener detalles de la asignación
      final asignacion = await getAsignacionDetails(asignacionId);
      if (asignacion == null) {
        return null;
      }

      // Obtener los ejercicios de la plantilla
      final ejercicios = await getEjerciciosDePlantilla(asignacion.plantillaId);

      // Obtener el nombre de la plantilla
      final plantillaResults = await _db.query(
        'SELECT nombre FROM rutinas_plantillas WHERE id = ?',
        [asignacion.plantillaId],
      );

      final plantillaNombre =
          plantillaResults.isNotEmpty
              ? plantillaResults.first.fields['nombre']
              : '';

      return {
        'asignacion': asignacion,
        'plantilla_nombre': plantillaNombre,
        'ejercicios': ejercicios,
      };
    }, operationName: 'getDetalleAsignacionConEjercicios($asignacionId)');
  }

  /// Actualiza el estado de una asignación (pendiente, en_progreso, completada, cancelada)
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<bool> updateAsignacionStatus(
    int asignacionId,
    String newStatus,
  ) async {
    return executeWithRetry(() async {
      await _db.query(
        'UPDATE asignaciones_agenda SET status = ? WHERE id = ?',
        [newStatus, asignacionId],
      );
      return true;
    }, operationName: 'updateAsignacionStatus($asignacionId)');
  }

  /// Añade o actualiza notas en una asignación
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<bool> addNoteToAsignacion(int asignacionId, String note) async {
    return executeWithRetry(() async {
      await _db.query('UPDATE asignaciones_agenda SET notes = ? WHERE id = ?', [
        note,
        asignacionId,
      ]);
      return true;
    }, operationName: 'addNoteToAsignacion($asignacionId)');
  }

  /// Añade feedback del asesorado después de completar una asignación
  /// Típicamente se utiliza para registrar cómo se sintió el cliente durante la sesión
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<bool> addFeedbackToAsignacion(
    int asignacionId,
    String feedback,
  ) async {
    return executeWithRetry(() async {
      await _db.query(
        'UPDATE asignaciones_agenda SET feedback_asesorado = ? WHERE id = ?',
        [feedback, asignacionId],
      );
      return true;
    }, operationName: 'addFeedbackToAsignacion($asignacionId)');
  }

  /// Busca ejercicios en la librería maestra (ejercicios_maestro)
  /// Utilizado para sugerir ejercicios al crear o editar rutinas
  /// Busca por nombre, músculo principal o equipamiento
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<List<EjercicioMaestro>> buscarEjerciciosMaestro(String query) async {
    if (query.isEmpty) {
      return [];
    }

    return executeWithRetry(() async {
      final searchPattern = '%$query%';
      const sql = '''
          SELECT id, nombre, musculo_principal, equipamiento, video_url, fuente
          FROM ejercicios_maestro
          WHERE nombre LIKE ? 
            OR musculo_principal LIKE ? 
            OR equipamiento LIKE ?
          LIMIT 20
        ''';

      final results = await _db.query(sql, [
        searchPattern,
        searchPattern,
        searchPattern,
      ]);

      return results
          .map((row) => EjercicioMaestro.fromMap(row.fields))
          .toList();
    }, operationName: 'buscarEjerciciosMaestro');
  }

  /// Obtiene TODOS los ejercicios de la biblioteca maestra (ejercicios_maestro)
  /// Utilizado para inicializar el buscador con todos los ejercicios disponibles
  /// Incluye todas las columnas necesarias para filtrado y visualización
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<List<EjercicioMaestro>> obtenerTodosEjerciciosMaestro() async {
    return executeWithRetry(() async {
      const sql = '''
          SELECT id, nombre, musculo_principal, equipamiento, video_url, image_url, fuente
          FROM ejercicios_maestro
          ORDER BY nombre ASC
        ''';

      final results = await _db.query(sql);
      return results
          .map((row) => EjercicioMaestro.fromMap(row.fields))
          .toList();
    }, operationName: 'obtenerTodosEjerciciosMaestro');
  }

  // ============================================================================
  // MÉTODOS DE ENTRENAMIENTOS RECIENTES (anteriormente en EntrenamientosService)
  // ============================================================================

  /// Obtiene los entrenamientos recientes (asignaciones programadas) para un asesorado
  /// Ordenados por fecha y hora de forma descendente
  /// Limitado por defecto a 8 registros
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<List<Asignacion>> getEntrenamientosRecientes(
    int asesoradoId, {
    int limit = 8,
  }) async {
    return executeWithRetry(() async {
      final results = await _db.query(
        '''
          SELECT 
            aa.id,
            aa.asesorado_id,
            aa.plantilla_id,
            aa.batch_id,
            aa.fecha_asignada,
            aa.hora_asignada,
            aa.status,
            aa.notes,
            aa.feedback_asesorado,
            rp.nombre AS rutina_nombre
          FROM asignaciones_agenda aa
          JOIN rutinas_plantillas rp ON aa.plantilla_id = rp.id
          WHERE aa.asesorado_id = ?
          ORDER BY aa.fecha_asignada DESC, aa.hora_asignada ASC
          LIMIT ?
          '''.trim(),
        [asesoradoId, limit],
      );

      return results.map((row) => Asignacion.fromMap(row.fields)).toList();
    }, operationName: 'getEntrenamientosRecientes($asesoradoId)');
  }

  // ============================================================================
  // MÉTODOS DE CREACIÓN Y GESTIÓN DE LOTES (anteriormente en RoutineAssignmentService)
  // ============================================================================

  /// Crea un lote (batch) de asignaciones de rutina para múltiples días
  /// Realiza una transacción atómica: si algo falla, se revierten todos los INSERTs
  /// FASE J: Captura snapshot de ejercicios en cada asignación para desacoplar plan del registro
  /// Retorna el ID del nuevo batch creado
  /// 🔧 CORRECCIÓN #2: Envuelto en transacción nativa para garantizar consistencia
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<int> createBatch({
    required int asesoradoId,
    required int rutinaId,
    required DateTime startDate,
    DateTime? endDate,
    TimeOfDay? defaultTime,
    String? notes,
    required List<RoutineDayAssignment> dayAssignments,
  }) async {
    return executeWithRetry(() async {
      final enabledAssignments =
          dayAssignments.where((entry) => entry.enabled).toList();
      if (enabledAssignments.isEmpty) {
        throw ArgumentError('Debe existir al menos un día seleccionado.');
      }

      final defaultTimeFormatted = _formatTime(defaultTime);
      final startDateFormatted = _dateFormatter.format(_normalize(startDate));
      final endDateFormatted =
          endDate != null ? _dateFormatter.format(_normalize(endDate)) : null;

      // Obtener conexión para usar transacción explícita
      final connection = await _db.connection;

      int batchId = 0;

      try {
        // Iniciar transacción explícita
        await connection.query('START TRANSACTION');

        // Insertar el batch
        final batchInsert = await connection.query(
          'INSERT INTO rutina_batches (asesorado_id, rutina_id, start_date, end_date, default_time, notes) VALUES (?, ?, ?, ?, ?, ?)',
          [
            asesoradoId,
            rutinaId,
            startDateFormatted,
            endDateFormatted,
            defaultTimeFormatted,
            notes,
          ],
        );

        batchId = batchInsert.insertId ?? 0;
        if (batchId == 0) {
          throw StateError(
            'No se pudo obtener el identificador del lote creado.',
          );
        }

        // FASE J: Obtener ejercicios de la plantilla UNA VEZ para capturar snapshot
        final ejercicios = await getEjerciciosDePlantilla(rutinaId);

        // Insertar asignaciones y snapshots dentro de la transacción
        for (final entry in enabledAssignments) {
          final dateFormatted = _dateFormatter.format(_normalize(entry.date));
          final timeFormatted = _formatTime(entry.time) ?? defaultTimeFormatted;
          final mergedNotes =
              entry.notes?.trim().isNotEmpty == true ? entry.notes : notes;

          final asignacionInsert = await connection.query(
            'INSERT INTO asignaciones_agenda (asesorado_id, plantilla_id, batch_id, fecha_asignada, hora_asignada, status, notes) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [
              asesoradoId,
              rutinaId,
              batchId,
              dateFormatted,
              timeFormatted,
              'pendiente',
              mergedNotes,
            ],
          );

          final asignacionId = asignacionInsert.insertId;
          if (asignacionId != null) {
            // FASE J: Capturar snapshot de ejercicios para esta asignación
            // Usando connection para que participe en la transacción
            await _crearSnapshotEjerciciosConConnection(
              asignacionId,
              ejercicios,
              connection,
            );
          }
        }

        // Commit si todo fue bien
        await connection.query('COMMIT');

        return batchId;
      } catch (e) {
        // Rollback en caso de error
        try {
          await connection.query('ROLLBACK');
        } catch (_) {
          // Ignorar error en rollback
        }
        rethrow;
      }
    }, operationName: 'createBatch');
  }

  /// Versión de _crearSnapshotEjercicios que usa una conexión específica
  /// Utilizada dentro de transacciones explícitas en createBatch
  Future<void> _crearSnapshotEjerciciosConConnection(
    int asignacionId,
    List<Ejercicio> ejercicios,
    MySqlConnection connection,
  ) async {
    for (final ejercicio in ejercicios) {
      await connection.query(
        '''
        INSERT INTO log_ejercicios 
        (asignacion_id, ejercicio_maestro_id, orden, series_planificadas, 
         reps_planificados, carga_planificada, descanso_planificado, notas_planificadas)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          asignacionId,
          ejercicio.ejercicioMaestroId,
          ejercicio.orden,
          ejercicio.series,
          ejercicio.repeticiones,
          ejercicio.indicadorCarga,
          ejercicio.descanso,
          ejercicio.notas,
        ],
      );
    }
  }

  /// Cancela una asignación individual sin afectar el lote completo
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<void> cancelAssignment(int assignmentId) async {
    return executeWithRetry(
      () => _db.query(
        'UPDATE asignaciones_agenda SET status = ? WHERE id = ?',
        ['cancelada', assignmentId],
      ),
      operationName: 'cancelAssignment($assignmentId)',
    );
  }

  /// Actualiza la hora de una asignación
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<void> updateAssignmentTime({
    required int assignmentId,
    TimeOfDay? time,
  }) async {
    return executeWithRetry(
      () => _db.query(
        'UPDATE asignaciones_agenda SET hora_asignada = ? WHERE id = ?',
        [_formatTime(time), assignmentId],
      ),
      operationName: 'updateAssignmentTime($assignmentId)',
    );
  }

  /// Actualiza las notas de una asignación
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<void> updateAssignmentNotes({
    required int assignmentId,
    String? notes,
  }) async {
    return executeWithRetry(
      () => _db.query('UPDATE asignaciones_agenda SET notes = ? WHERE id = ?', [
        notes,
        assignmentId,
      ]),
      operationName: 'updateAssignmentNotes($assignmentId)',
    );
  }

  /// Elimina un lote por su ID (operación de bajo nivel)
  /// Nota: Generalmente deberías usar deleteLoteCompleto() en su lugar
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<void> deleteBatch(int batchId) async {
    return executeWithRetry(
      () => _db.query('DELETE FROM rutina_batches WHERE id = ?', [batchId]),
      operationName: 'deleteBatch($batchId)',
    );
  }

  /// Obtiene todos los lotes programados para un asesorado con información de la rutina
  /// Incluye JOIN con rutinas_plantillas para obtener el nombre
  /// Ordenados por fecha de inicio descendente
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<List<RutinaBatchDetalle>> getLotesPorAsesorado(int asesoradoId) async {
    return executeWithRetry(() async {
      const sql = '''
          SELECT b.*, r.nombre as rutina_nombre 
          FROM rutina_batches b
          JOIN rutinas_plantillas r ON b.rutina_id = r.id
          WHERE b.asesorado_id = ?
          ORDER BY b.start_date DESC
        ''';

      final results = await _db.query(sql, [asesoradoId]);
      return results
          .map((row) => RutinaBatchDetalle.fromMap(row.fields))
          .toList();
    }, operationName: 'getLotesPorAsesorado($asesoradoId)');
  }

  /// Elimina un lote completo junto con todas sus asignaciones
  /// Realiza una "transacción lógica":
  /// 1. Elimina todas las asignaciones del lote
  /// 2. Elimina el registro del lote
  /// Retorna true si tiene éxito, false si hay error
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<bool> deleteLoteCompleto(int batchId) async {
    return executeWithRetry(() async {
      try {
        // Eliminar todas las asignaciones del lote
        await _db.query('DELETE FROM asignaciones_agenda WHERE batch_id = ?', [
          batchId,
        ]);

        // Eliminar el registro del lote
        await _db.query('DELETE FROM rutina_batches WHERE id = ?', [batchId]);

        return true;
      } catch (e) {
        debugPrint('Error eliminando lote completo: $e');
        return false;
      }
    }, operationName: 'deleteLoteCompleto($batchId)');
  }

  // ============================================================================
  // MÉTODOS DE LOG DE EJERCICIOS (FASE J: Sistema de Snapshot)
  // ============================================================================

  /// FASE J: Crea un snapshot de todos los ejercicios de una asignación
  /// Captura los valores planificados en el momento de la asignación
  /// para desacoplar el PLAN del REGISTRO
  ///
  /// Cuando se modifique la plantilla después, esto no afecta el historial
  /// FASE J: Obtiene todos los ejercicios snapshot de una asignación
  /// Lee de log_ejercicios para mostrar el plan ORIGINAL (no cambios posteriores)
  /// Incluye JOIN con ejercicios_maestro para información del ejercicio
  Future<List<LogEjercicio>> getLogEjerciciosDeAsignacion(
    int asignacionId,
  ) async {
    try {
      const sql = '''
        SELECT 
          le.id, le.asignacion_id, le.ejercicio_maestro_id, le.orden,
          le.series_planificadas, le.reps_planificados, le.carga_planificada,
          le.descanso_planificado, le.notas_planificadas, le.created_at
        FROM log_ejercicios le
        WHERE le.asignacion_id = ?
        ORDER BY le.orden ASC
      ''';

      final results = await _db.query(sql, [asignacionId]);
      return results.map((row) => LogEjercicio.fromMap(row.fields)).toList();
    } catch (e) {
      debugPrint('Error obteniendo log de ejercicios: $e');
      return [];
    }
  }

  /// FASE J: Registra una serie completada por el asesorado
  /// Captura el desempeño REAL vs. lo PLANIFICADO
  ///
  /// Parámetros:
  /// - logEjercicioId: ID del ejercicio snapshot
  /// - numSerie: Número de serie (1, 2, 3, etc.)
  /// - repsLogradas: Repeticiones reales completadas
  /// - cargaLograda: Carga real usada en kg
  /// - notas: Feedback del asesorado
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<int> registrarSerie({
    required int logEjercicioId,
    required int numSerie,
    required int repsLogradas,
    double? cargaLograda,
    String? notas,
  }) async {
    return executeWithRetry(() async {
      final result = await _db.query(
        '''
          INSERT INTO log_series 
          (log_ejercicio_id, num_serie, reps_logradas, carga_lograda, completada, notas)
          VALUES (?, ?, ?, ?, ?, ?)
          ''',
        [logEjercicioId, numSerie, repsLogradas, cargaLograda, true, notas],
      );

      return result.insertId ?? 0;
    }, operationName: 'registrarSerie($logEjercicioId, serie: $numSerie)');
  }

  /// FASE J: Obtiene todas las series completadas para un ejercicio snapshot
  /// Retorna lista de LogSerie ordenadas por número de serie
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<List<LogSerie>> getLogSeriesDeEjercicio(int logEjercicioId) async {
    return executeWithRetry(() async {
      const sql = '''
          SELECT 
            id, log_ejercicio_id, num_serie, reps_logradas, 
            carga_lograda, completada, notas, created_at
          FROM log_series
          WHERE log_ejercicio_id = ?
          ORDER BY num_serie ASC
        ''';

      final results = await _db.query(sql, [logEjercicioId]);
      return results.map((row) => LogSerie.fromMap(row.fields)).toList();
    }, operationName: 'getLogSeriesDeEjercicio($logEjercicioId)');
  }

  /// FASE J: Actualiza una serie (para permitir correcciones)
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<bool> actualizarSerie({
    required int serieId,
    required int repsLogradas,
    double? cargaLograda,
    String? notas,
  }) async {
    return executeWithRetry(() async {
      try {
        await _db.query(
          '''
            UPDATE log_series
            SET reps_logradas = ?, carga_lograda = ?, notas = ?
            WHERE id = ?
            ''',
          [repsLogradas, cargaLograda, notas, serieId],
        );
        return true;
      } catch (e) {
        debugPrint('Error actualizando serie: $e');
        return false;
      }
    }, operationName: 'actualizarSerie($serieId)');
  }

  // ============================================================================
  // MÉTODOS AUXILIARES
  // ============================================================================

  /// Normaliza una DateTime al inicio del día (00:00:00)
  DateTime _normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Formatea un TimeOfDay a string HH:MM:SS
  /// Retorna null si el input es null
  String? _formatTime(TimeOfDay? time) {
    if (time == null) return null;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }
}
