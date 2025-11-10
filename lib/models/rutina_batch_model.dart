// lib/models/rutina_batch_model.dart

import 'package:flutter/material.dart';

class RutinaBatch {
  final int id;
  final int asesoradoId;
  final int rutinaId;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final TimeOfDay? defaultTime;

  RutinaBatch({
    required this.id,
    required this.asesoradoId,
    required this.rutinaId,
    required this.startDate,
    this.endDate,
    this.notes,
    this.defaultTime,
  });

  factory RutinaBatch.fromMap(Map<String, dynamic> map) {
    final defaultTimeRaw = map['default_time']?.toString();
    TimeOfDay? defaultTime;
    if (defaultTimeRaw != null && defaultTimeRaw.isNotEmpty) {
      final parts = defaultTimeRaw.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          defaultTime = TimeOfDay(hour: hour, minute: minute);
        }
      }
    }

    return RutinaBatch(
      id: int.tryParse(map['id'].toString()) ?? 0,
      asesoradoId: int.tryParse(map['asesorado_id'].toString()) ?? 0,
      rutinaId: int.tryParse(map['rutina_id'].toString()) ?? 0,
      startDate: DateTime.parse(map['start_date'].toString()),
      endDate:
          map['end_date'] != null
              ? DateTime.tryParse(map['end_date'].toString())
              : null,
      notes: map['notes']?.toString(),
      defaultTime: defaultTime,
    );
  }
}
