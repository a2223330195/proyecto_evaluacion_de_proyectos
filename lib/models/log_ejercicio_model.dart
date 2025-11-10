import 'package:intl/intl.dart';

/// Modelo LogEjercicio
///
/// Representa un SNAPSHOT de un ejercicio planificado en el momento de la asignación.
/// Este modelo desacopla el PLAN (plantilla) del REGISTRO (historial real).
///
/// Cuando un coach asigna una rutina a un asesorado, se crea una copia inmutable
/// de los datos del ejercicio en este momento. Cambios posteriores en la plantilla
/// NO afectarán este registro histórico.
///
/// Relación con otras tablas:
/// - asignacion_id: FK a asignaciones_agenda (la asignación que generó este log)
/// - ejercicio_maestro_id: FK a ejercicios_maestro (referencia al ejercicio base)
///
/// Los valores planificados (_planificad*) son capturas del momento de la asignación.
/// El desempeño real se registra en log_series (tabla separada).
class LogEjercicio {
  final int id;
  final int asignacionId;
  final int ejercicioMaestroId;
  final int orden;
  final String seriesPlanificadas; // Snapshot: "3", "4", etc.
  final String repsPlanificados; // Snapshot: "8-12", "10", "Al fallo", etc.
  final String? cargaPlanificada; // Snapshot: "50kg", "RPE 8", etc.
  final String? descansosPlanificado; // Snapshot: "90s", "3min", etc.
  final String? notasPlanificadas; // Snapshot: Notas originales del plan
  final DateTime createdAt;

  LogEjercicio({
    required this.id,
    required this.asignacionId,
    required this.ejercicioMaestroId,
    required this.orden,
    required this.seriesPlanificadas,
    required this.repsPlanificados,
    this.cargaPlanificada,
    this.descansosPlanificado,
    this.notasPlanificadas,
    required this.createdAt,
  });

  /// Convierte un Map (resultado de query) a objeto LogEjercicio
  factory LogEjercicio.fromMap(Map<String, dynamic> map) {
    return LogEjercicio(
      id: map['id'] as int,
      asignacionId: map['asignacion_id'] as int,
      ejercicioMaestroId: map['ejercicio_maestro_id'] as int,
      orden: map['orden'] as int,
      seriesPlanificadas: _safeToString(map['series_planificadas']),
      repsPlanificados: _safeToString(map['reps_planificados']),
      cargaPlanificada: _safeToStringNullable(map['carga_planificada']),
      descansosPlanificado: _safeToStringNullable(map['descanso_planificado']),
      notasPlanificadas: _safeToStringNullable(map['notas_planificadas']),
      createdAt:
          map['created_at'] is String
              ? DateTime.parse(map['created_at'] as String)
              : map['created_at'] as DateTime,
    );
  }

  /// Convierte seguramente cualquier tipo a String
  static String _safeToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is List<int>) {
      // Convertir Blob (List<int>) a String UTF-8
      return String.fromCharCodes(value);
    }
    return value.toString();
  }

  /// Convierte seguramente cualquier tipo a String nullable
  static String? _safeToStringNullable(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is List<int>) {
      // Convertir Blob (List<int>) a String UTF-8
      return String.fromCharCodes(value);
    }
    return value.toString();
  }

  /// Convierte el objeto a Map para insertar en BD
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asignacion_id': asignacionId,
      'ejercicio_maestro_id': ejercicioMaestroId,
      'orden': orden,
      'series_planificadas': seriesPlanificadas,
      'reps_planificados': repsPlanificados,
      'carga_planificada': cargaPlanificada,
      'descanso_planificado': descansosPlanificado,
      'notas_planificadas': notasPlanificadas,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Crea un mapa sin el campo id (para INSERT)
  Map<String, dynamic> toMapForInsert() {
    final map = toMap();
    map.remove('id');
    return map;
  }

  /// Retorna una copia del objeto con cambios opcionales
  LogEjercicio copyWith({
    int? id,
    int? asignacionId,
    int? ejercicioMaestroId,
    int? orden,
    String? seriesPlanificadas,
    String? repsPlanificados,
    String? cargaPlanificada,
    String? descansosPlanificado,
    String? notasPlanificadas,
    DateTime? createdAt,
  }) {
    return LogEjercicio(
      id: id ?? this.id,
      asignacionId: asignacionId ?? this.asignacionId,
      ejercicioMaestroId: ejercicioMaestroId ?? this.ejercicioMaestroId,
      orden: orden ?? this.orden,
      seriesPlanificadas: seriesPlanificadas ?? this.seriesPlanificadas,
      repsPlanificados: repsPlanificados ?? this.repsPlanificados,
      cargaPlanificada: cargaPlanificada ?? this.cargaPlanificada,
      descansosPlanificado: descansosPlanificado ?? this.descansosPlanificado,
      notasPlanificadas: notasPlanificadas ?? this.notasPlanificadas,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return 'LogEjercicio('
        'id: $id, '
        'asignacionId: $asignacionId, '
        'orden: $orden, '
        'series: $seriesPlanificadas, '
        'reps: $repsPlanificados, '
        'carga: $cargaPlanificada, '
        'createdAt: ${formatter.format(createdAt)}'
        ')';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogEjercicio &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          asignacionId == other.asignacionId &&
          ejercicioMaestroId == other.ejercicioMaestroId;

  @override
  int get hashCode =>
      id.hashCode ^ asignacionId.hashCode ^ ejercicioMaestroId.hashCode;
}
