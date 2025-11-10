// lib/services/routine_assignment_service.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:coachhub/models/rutina_batch_detalle_model.dart';
import 'db_connection.dart';

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

class RoutineAssignmentService {
  RoutineAssignmentService();

  final _dateFormatter = DateFormat('yyyy-MM-dd');

  Future<int> createBatch({
    required int asesoradoId,
    required int rutinaId,
    required DateTime startDate,
    DateTime? endDate,
    TimeOfDay? defaultTime,
    String? notes,
    required List<RoutineDayAssignment> dayAssignments,
  }) async {
    final enabledAssignments =
        dayAssignments.where((entry) => entry.enabled).toList();
    if (enabledAssignments.isEmpty) {
      throw ArgumentError('Debe existir al menos un día seleccionado.');
    }

    final db = DatabaseConnection.instance;

    final defaultTimeFormatted = _formatTime(defaultTime);
    final startDateFormatted = _dateFormatter.format(_normalize(startDate));
    final endDateFormatted =
        endDate != null ? _dateFormatter.format(_normalize(endDate)) : null;

    final batchInsert = await db.query(
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

    final batchId = batchInsert.insertId;
    if (batchId == null) {
      throw StateError('No se pudo obtener el identificador del lote creado.');
    }

    for (final entry in enabledAssignments) {
      final dateFormatted = _dateFormatter.format(_normalize(entry.date));
      final timeFormatted = _formatTime(entry.time) ?? defaultTimeFormatted;
      final mergedNotes =
          entry.notes?.trim().isNotEmpty == true ? entry.notes : notes;

      await db.query(
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
    }

    return batchId;
  }

  Future<void> cancelAssignment(int assignmentId) async {
    final db = DatabaseConnection.instance;
    await db.query('UPDATE asignaciones_agenda SET status = ? WHERE id = ?', [
      'cancelada',
      assignmentId,
    ]);
  }

  Future<void> updateAssignmentTime({
    required int assignmentId,
    TimeOfDay? time,
  }) async {
    final db = DatabaseConnection.instance;
    await db.query(
      'UPDATE asignaciones_agenda SET hora_asignada = ? WHERE id = ?',
      [_formatTime(time), assignmentId],
    );
  }

  Future<void> updateAssignmentNotes({
    required int assignmentId,
    String? notes,
  }) async {
    final db = DatabaseConnection.instance;
    await db.query('UPDATE asignaciones_agenda SET notes = ? WHERE id = ?', [
      notes,
      assignmentId,
    ]);
  }

  Future<void> deleteBatch(int batchId) async {
    final db = DatabaseConnection.instance;
    await db.query('DELETE FROM rutina_batches WHERE id = ?', [batchId]);
  }

  // --- MEJORA 3: GESTIÓN DE LOTES ---

  /// Obtiene todos los lotes programados para un asesorado
  /// Incluye información de la rutina mediante JOIN
  Future<List<RutinaBatchDetalle>> getLotesPorAsesorado(int asesoradoId) async {
    final db = DatabaseConnection.instance;
    const sql = '''
      SELECT b.*, r.nombre as rutina_nombre 
      FROM rutina_batches b
      JOIN rutinas_plantillas r ON b.rutina_id = r.id
      WHERE b.asesorado_id = ?
      ORDER BY b.start_date DESC
    ''';

    try {
      final results = await db.query(sql, [asesoradoId]);
      return results
          .map((row) => RutinaBatchDetalle.fromMap(row.fields))
          .toList();
    } catch (e) {
      debugPrint('Error cargando lotes: $e');
      return [];
    }
  }

  /// Elimina un lote completo junto con todas sus asignaciones
  /// Esto es una transacción lógica: primero elimina las asignaciones, luego el lote
  Future<bool> deleteLoteCompleto(int batchId) async {
    final db = DatabaseConnection.instance;

    try {
      // Eliminar todas las asignaciones del lote
      await db.query('DELETE FROM asignaciones_agenda WHERE batch_id = ?', [
        batchId,
      ]);

      // Eliminar el registro del lote
      await db.query('DELETE FROM rutina_batches WHERE id = ?', [batchId]);

      return true;
    } catch (e) {
      debugPrint('Error eliminando lote completo: $e');
      return false;
    }
  }

  DateTime _normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String? _formatTime(TimeOfDay? time) {
    if (time == null) return null;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }
}
