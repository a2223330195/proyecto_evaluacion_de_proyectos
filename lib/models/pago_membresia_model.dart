enum TipoPago { completo, abono }

class PagoMembresia {
  final int id;
  final int asesoradoId;
  final DateTime fechaPago;
  final double monto;
  final String periodo; // YYYY-MM
  final TipoPago tipo; // completo o abono
  final String? nota;

  PagoMembresia({
    required this.id,
    required this.asesoradoId,
    required this.fechaPago,
    required this.monto,
    required this.periodo,
    this.tipo = TipoPago.completo,
    this.nota,
  });

  factory PagoMembresia.fromMap(Map<String, dynamic> map) {
    final tipoStr = map['tipo']?.toString() ?? 'completo';
    TipoPago tipoEnum = TipoPago.completo;
    try {
      tipoEnum = TipoPago.values.firstWhere(
        (e) => e.name == tipoStr.toLowerCase(),
      );
    } catch (e) {
      tipoEnum = TipoPago.completo;
    }

    return PagoMembresia(
      id: int.tryParse(map['id'].toString()) ?? 0,
      asesoradoId: int.tryParse(map['asesorado_id'].toString()) ?? 0,
      fechaPago:
          map['fecha_pago'] == null
              ? DateTime(1970, 1, 1)
              : DateTime.parse(map['fecha_pago'].toString()),
      monto: double.tryParse(map['monto']?.toString() ?? '0.0') ?? 0.0,
      periodo:
          map['periodo']?.toString() ??
          DateTime.now().toString().substring(0, 7),
      tipo: tipoEnum,
      nota: map['nota']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asesorado_id': asesoradoId,
      'fecha_pago': fechaPago.toIso8601String(),
      'monto': monto,
      'periodo': periodo,
      'tipo': tipo.name,
      'nota': nota,
    };
  }

  PagoMembresia copyWith({
    int? id,
    int? asesoradoId,
    DateTime? fechaPago,
    double? monto,
    String? periodo,
    TipoPago? tipo,
    String? nota,
  }) {
    return PagoMembresia(
      id: id ?? this.id,
      asesoradoId: asesoradoId ?? this.asesoradoId,
      fechaPago: fechaPago ?? this.fechaPago,
      monto: monto ?? this.monto,
      periodo: periodo ?? this.periodo,
      tipo: tipo ?? this.tipo,
      nota: nota ?? this.nota,
    );
  }
}
