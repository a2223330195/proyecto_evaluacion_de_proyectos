import 'package:intl/intl.dart';

/// Modelo LogSerie
///
/// Representa el DESEMPEÑO REAL de una serie completada por el asesorado.
/// Desacoplado del plan original (LogEjercicio) para permitir variabilidad.
///
/// El asesorado puede completar una serie con:
/// - Más reps de las planificadas
/// - Menos reps de las planificadas
/// - Diferente carga de la planificada
/// - Notas sobre la dificultad
///
/// Esto permite tracking completo del progreso real vs. planificado.
///
/// Relación con otras tablas:
/// - log_ejercicio_id: FK a log_ejercicios (qué ejercicio se estaba realizando)
class LogSerie {
  final int id;
  final int logEjercicioId;
  final int numSerie; // Número de serie: 1, 2, 3, etc.
  final int repsLogradas; // Repeticiones reales completadas
  final double? cargaLograda; // Carga real usada en kg
  final bool completada; // ¿Se completó la serie? (true por defecto)
  final String? notas; // Feedback del asesorado: "Muy pesado", "Fácil", etc.
  final DateTime createdAt;

  LogSerie({
    required this.id,
    required this.logEjercicioId,
    required this.numSerie,
    required this.repsLogradas,
    this.cargaLograda,
    required this.completada,
    this.notas,
    required this.createdAt,
  });

  /// Convierte un Map (resultado de query) a objeto LogSerie
  factory LogSerie.fromMap(Map<String, dynamic> map) {
    return LogSerie(
      id: map['id'] as int,
      logEjercicioId: map['log_ejercicio_id'] as int,
      numSerie: map['num_serie'] as int,
      repsLogradas: map['reps_logradas'] as int,
      cargaLograda:
          map['carga_lograda'] is String
              ? double.tryParse(map['carga_lograda'] as String)
              : (map['carga_lograda'] as double?),
      completada:
          (map['completada'] is int)
              ? (map['completada'] as int) == 1
              : (map['completada'] as bool? ?? true),
      notas: _safeToStringNullable(map['notas']),
      createdAt:
          map['created_at'] is String
              ? DateTime.parse(map['created_at'] as String)
              : map['created_at'] as DateTime,
    );
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
      'log_ejercicio_id': logEjercicioId,
      'num_serie': numSerie,
      'reps_logradas': repsLogradas,
      'carga_lograda': cargaLograda,
      'completada': completada ? 1 : 0,
      'notas': notas,
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
  LogSerie copyWith({
    int? id,
    int? logEjercicioId,
    int? numSerie,
    int? repsLogradas,
    double? cargaLograda,
    bool? completada,
    String? notas,
    DateTime? createdAt,
  }) {
    return LogSerie(
      id: id ?? this.id,
      logEjercicioId: logEjercicioId ?? this.logEjercicioId,
      numSerie: numSerie ?? this.numSerie,
      repsLogradas: repsLogradas ?? this.repsLogradas,
      cargaLograda: cargaLograda ?? this.cargaLograda,
      completada: completada ?? this.completada,
      notas: notas ?? this.notas,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return 'LogSerie('
        'id: $id, '
        'numSerie: $numSerie, '
        'repsLogradas: $repsLogradas, '
        'cargaLograda: $cargaLograda kg, '
        'completada: $completada, '
        'createdAt: ${formatter.format(createdAt)}'
        ')';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogSerie &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          logEjercicioId == other.logEjercicioId &&
          numSerie == other.numSerie;

  @override
  int get hashCode => id.hashCode ^ logEjercicioId.hashCode ^ numSerie.hashCode;
}
