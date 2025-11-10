// lib/models/asignacion_model.dart

import 'package:flutter/material.dart';

class Asignacion {
  final int id;
  final int asesoradoId;
  final int plantillaId;
  final DateTime fechaAsignada;
  final String status;
  final int? batchId;
  final String? notes;
  final String?
  feedbackAsesorado; // Nuevo: feedback del asesorado sobre cómo le fue
  final String? horaAsignadaRaw;

  // Datos extra (de los JOINs)
  final String? asesoradoNombre;
  final String? rutinaNombre;
  final String? asesoradoAvatarUrl;

  Asignacion({
    required this.id,
    required this.asesoradoId,
    required this.plantillaId,
    required this.fechaAsignada,
    required this.status,
    this.batchId,
    this.notes,
    this.feedbackAsesorado,
    this.horaAsignadaRaw,
    this.asesoradoNombre,
    this.rutinaNombre,
    this.asesoradoAvatarUrl,
  });

  factory Asignacion.fromMap(Map<String, dynamic> map) {
    return Asignacion(
      id: int.tryParse(map['id'].toString()) ?? 0,
      asesoradoId: int.tryParse(map['asesorado_id'].toString()) ?? 0,
      plantillaId: int.tryParse(map['plantilla_id'].toString()) ?? 0,
      fechaAsignada: DateTime.parse(map['fecha_asignada'].toString()),
      status: map['status'],
      batchId:
          map.containsKey('batch_id') && map['batch_id'] != null
              ? int.tryParse(map['batch_id'].toString())
              : null,
      notes: map['notes']?.toString(),
      feedbackAsesorado: map['feedback_asesorado']?.toString(),
      horaAsignadaRaw: map['hora_asignada']?.toString(),
      asesoradoNombre: map['asesorado_nombre']?.toString(),
      rutinaNombre: map['rutina_nombre']?.toString(),
      asesoradoAvatarUrl: map['asesorado_avatar_url']?.toString(),
    );
  }

  TimeOfDay? get horaAsignada {
    if (horaAsignadaRaw == null || horaAsignadaRaw!.isEmpty) {
      return null;
    }
    final parts = horaAsignadaRaw!.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }
}
