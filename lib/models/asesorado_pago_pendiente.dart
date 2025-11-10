import 'package:equatable/equatable.dart';

/// Modelo unificado para representar un asesorado con pagos pendientes.
/// Reemplaza las implementaciones duplicadas en el BLoC y el servicio.
class AsesoradoPagoPendiente extends Equatable {
  final int asesoradoId;
  final String nombre;
  final String? fotoPerfil;
  final String? plan;
  final double montoPendiente;
  final DateTime fechaVencimiento;
  final String estado;
  final double? costoPlan;
  final String? email;
  final String? telefonoContacto;

  const AsesoradoPagoPendiente({
    required this.asesoradoId,
    required this.nombre,
    this.fotoPerfil,
    this.plan,
    required this.montoPendiente,
    required this.fechaVencimiento,
    required this.estado,
    this.costoPlan,
    this.email,
    this.telefonoContacto,
  });

  @override
  List<Object?> get props => [
    asesoradoId,
    nombre,
    fotoPerfil,
    plan,
    montoPendiente,
    fechaVencimiento,
    estado,
    costoPlan,
    email,
    telefonoContacto,
  ];

  factory AsesoradoPagoPendiente.fromMap(Map<String, dynamic> map) {
    final fecha = _parseFecha(map['fecha_vencimiento']);
    final resolvedEstado = _resolveEstado(map['estado'], fecha);

    return AsesoradoPagoPendiente(
      asesoradoId: _parseInt(map['asesorado_id']),
      nombre: _parseString(map['nombre'], fallback: 'Sin nombre'),
      fotoPerfil:
          _parseOptionalString(map['foto_perfil']) ??
          _parseOptionalString(map['avatar_url']),
      plan:
          _parseOptionalString(map['plan']) ??
          _parseOptionalString(map['plan_nombre']),
      montoPendiente: _parseDouble(map['monto_pendiente']),
      fechaVencimiento: fecha,
      estado: resolvedEstado,
      costoPlan: _parseOptionalDouble(map['costo_plan'] ?? map['plan_costo']),
      email: _parseOptionalString(map['email']),
      telefonoContacto:
          _parseOptionalString(map['telefono_contacto']) ??
          _parseOptionalString(map['telefono']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'asesorado_id': asesoradoId,
      'nombre': nombre,
      'foto_perfil': fotoPerfil,
      'plan': plan,
      'monto_pendiente': montoPendiente,
      'fecha_vencimiento': fechaVencimiento.toIso8601String(),
      'estado': estado,
      'costo_plan': costoPlan,
      'email': email,
      'telefono_contacto': telefonoContacto,
    };
  }

  AsesoradoPagoPendiente copyWith({
    int? asesoradoId,
    String? nombre,
    String? fotoPerfil,
    String? plan,
    double? montoPendiente,
    DateTime? fechaVencimiento,
    String? estado,
    double? costoPlan,
    String? email,
    String? telefonoContacto,
  }) {
    return AsesoradoPagoPendiente(
      asesoradoId: asesoradoId ?? this.asesoradoId,
      nombre: nombre ?? this.nombre,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
      plan: plan ?? this.plan,
      montoPendiente: montoPendiente ?? this.montoPendiente,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      estado: estado ?? this.estado,
      costoPlan: costoPlan ?? this.costoPlan,
      email: email ?? this.email,
      telefonoContacto: telefonoContacto ?? this.telefonoContacto,
    );
  }

  static DateTime _parseFecha(dynamic rawFecha) {
    if (rawFecha == null) {
      return DateTime.now();
    }
    if (rawFecha is DateTime) {
      return rawFecha;
    }
    return DateTime.tryParse(rawFecha.toString()) ?? DateTime.now();
  }

  static String _resolveEstado(dynamic rawEstado, DateTime fechaVencimiento) {
    if (rawEstado != null && rawEstado.toString().trim().isNotEmpty) {
      return rawEstado.toString().toLowerCase();
    }

    final diasRestantes = fechaVencimiento.difference(DateTime.now()).inDays;
    if (diasRestantes < 0) {
      return 'atrasado';
    }
    if (diasRestantes <= 7) {
      return 'proximo';
    }
    return 'pendiente';
  }

  static int _parseInt(dynamic raw) {
    if (raw is int) {
      return raw;
    }
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static double _parseDouble(dynamic raw) {
    if (raw is num) {
      return raw.toDouble();
    }
    return double.tryParse(raw?.toString() ?? '') ?? 0.0;
  }

  static double? _parseOptionalDouble(dynamic raw) {
    if (raw == null) {
      return null;
    }
    if (raw is num) {
      return raw.toDouble();
    }
    return double.tryParse(raw.toString());
  }

  static String _parseString(dynamic raw, {required String fallback}) {
    final result = _parseOptionalString(raw);
    return result?.isNotEmpty == true ? result! : fallback;
  }

  static String? _parseOptionalString(dynamic raw) {
    if (raw == null) {
      return null;
    }
    final value = raw.toString();
    return value.isEmpty ? null : value;
  }

  @override
  String toString() {
    return 'AsesoradoPagoPendiente(id: $asesoradoId, nombre: $nombre, monto: $montoPendiente, estado: $estado)';
  }
}
