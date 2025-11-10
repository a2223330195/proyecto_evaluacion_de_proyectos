// lib/models/plan_model.dart

class Plan {
  final int id;
  final String nombre;
  final double costo;
  final int? coachId;
  final DateTime createdAt;
  final bool activo;

  Plan({
    required this.id,
    required this.nombre,
    required this.costo,
    this.coachId,
    required this.createdAt,
    this.activo = true,
  });

  factory Plan.fromMap(Map<String, dynamic> map) {
    final createdAtStr = map['created_at'];
    DateTime createdAtParsed = DateTime.now();
    if (createdAtStr != null) {
      final parsed = DateTime.tryParse(createdAtStr.toString());
      if (parsed != null) {
        createdAtParsed = parsed;
      }
    }

    bool activoValue = true;
    if (map['activo'] != null) {
      final val = map['activo'];
      if (val is bool) {
        activoValue = val;
      } else if (val is int) {
        activoValue = val == 1;
      } else if (val is String) {
        activoValue = val.toLowerCase() == 'true' || val == '1';
      }
    }

    return Plan(
      id: int.tryParse(map['id'].toString()) ?? 0,
      nombre: map['nombre']?.toString() ?? 'Plan sin nombre',
      costo: double.tryParse(map['costo'].toString()) ?? 0.0,
      coachId:
          map['coach_id'] != null
              ? int.tryParse(map['coach_id'].toString())
              : null,
      createdAt: createdAtParsed,
      activo: activoValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'costo': costo,
      'coach_id': coachId,
      'created_at': createdAt.toIso8601String(),
      'activo': activo ? 1 : 0,
    };
  }

  Plan copyWith({
    int? id,
    String? nombre,
    double? costo,
    int? coachId,
    DateTime? createdAt,
    bool? activo,
  }) {
    return Plan(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      costo: costo ?? this.costo,
      coachId: coachId ?? this.coachId,
      createdAt: createdAt ?? this.createdAt,
      activo: activo ?? this.activo,
    );
  }
}
