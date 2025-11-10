// lib/models/nota_model.dart

class Nota {
  final int id;
  final int asesoradoId;
  final String contenido;
  final bool prioritaria;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final String? asesoradoNombre;

  Nota({
    required this.id,
    required this.asesoradoId,
    required this.contenido,
    this.prioritaria = false,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.asesoradoNombre,
  });

  factory Nota.fromMap(Map<String, dynamic> map) {
    bool prioritariaValue = false;
    if (map['prioritaria'] != null) {
      final val = map['prioritaria'];
      if (val is bool) {
        prioritariaValue = val;
      } else if (val is int) {
        prioritariaValue = val == 1;
      } else if (val is String) {
        prioritariaValue = val.toLowerCase() == 'true' || val == '1';
      }
    }

    return Nota(
      id: int.tryParse(map['id'].toString()) ?? 0,
      asesoradoId: int.tryParse(map['asesorado_id'].toString()) ?? 0,
      contenido: map['contenido']?.toString() ?? '',
      prioritaria: prioritariaValue,
      fechaCreacion:
          map['fecha_creacion'] == null
              ? DateTime.now()
              : DateTime.parse(map['fecha_creacion'].toString()),
      fechaActualizacion:
          map['fecha_actualizacion'] == null
              ? DateTime.now()
              : DateTime.parse(map['fecha_actualizacion'].toString()),
      asesoradoNombre: map['asesorado_nombre']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asesorado_id': asesoradoId,
      'contenido': contenido,
      'prioritaria': prioritaria ? 1 : 0,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion.toIso8601String(),
    };
  }

  Nota copyWith({
    int? id,
    int? asesoradoId,
    String? contenido,
    bool? prioritaria,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    String? asesoradoNombre,
  }) {
    return Nota(
      id: id ?? this.id,
      asesoradoId: asesoradoId ?? this.asesoradoId,
      contenido: contenido ?? this.contenido,
      prioritaria: prioritaria ?? this.prioritaria,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      asesoradoNombre: asesoradoNombre ?? this.asesoradoNombre,
    );
  }
}
