// lib/models/asesorado_model.dart

import '../utils/string_formatters.dart';

enum AsesoradoStatus { activo, enPausa, deudor }

extension AsesoradoStatusView on AsesoradoStatus {
  String get displayLabel => formatUserFacingLabel(name);
}

class Asesorado {
  final int id;
  final int? coachId;
  final String name;
  final String avatarUrl;
  final AsesoradoStatus status;
  final int? planId;
  final String? planName;
  final DateTime? dueDate;
  final DateTime? fechaNacimiento;
  final String? sexo;
  final double? alturaCm;
  final String? telefono;
  final DateTime? fechaInicioPrograma;
  final String? objetivoPrincipal;
  final String? objetivoSecundario;

  Asesorado({
    required this.id,
    this.coachId,
    required this.name,
    required this.avatarUrl,
    required this.status,
    this.planId,
    this.planName,
    this.dueDate,
    this.fechaNacimiento,
    this.sexo,
    this.alturaCm,
    this.telefono,
    this.fechaInicioPrograma,
    this.objetivoPrincipal,
    this.objetivoSecundario,
  });

  /// Getter que calcula dinámicamente la edad desde la fecha de nacimiento
  int? get edad {
    if (fechaNacimiento == null) return null;
    final now = DateTime.now();
    int calculatedAge = now.year - fechaNacimiento!.year;
    if (now.month < fechaNacimiento!.month ||
        (now.month == fechaNacimiento!.month &&
            now.day < fechaNacimiento!.day)) {
      calculatedAge--;
    }
    return calculatedAge;
  }

  factory Asesorado.fromMap(Map<String, dynamic> map) {
    final fechaVencimiento = map['fecha_vencimiento'];
    final fechaInicio = map['fecha_inicio_programa'];
    final fechaNacimientoStr = map['fecha_nacimiento'];

    DateTime? dueDateParsed;
    if (fechaVencimiento != null) {
      dueDateParsed = DateTime.tryParse(fechaVencimiento.toString());
    }

    DateTime? fechaInicioParsed;
    if (fechaInicio != null) {
      fechaInicioParsed = DateTime.tryParse(fechaInicio.toString());
    }

    DateTime? fechaNacimientoParsed;
    if (fechaNacimientoStr != null) {
      fechaNacimientoParsed = DateTime.tryParse(fechaNacimientoStr.toString());
    }

    return Asesorado(
      id: int.tryParse(map['id'].toString()) ?? 0,
      coachId:
          map['coach_id'] != null
              ? int.tryParse(map['coach_id'].toString())
              : null,
      name: map['nombre']?.toString() ?? 'Nombre no encontrado',
      avatarUrl: map['avatar_url']?.toString() ?? '',
      status: AsesoradoStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AsesoradoStatus.activo,
      ),
      planId:
          map['plan_id'] != null
              ? int.tryParse(map['plan_id'].toString())
              : null,
      planName: map['plan_nombre']?.toString(),
      dueDate: dueDateParsed,
      fechaNacimiento: fechaNacimientoParsed,
      sexo: map['sexo']?.toString(),
      alturaCm:
          map['altura_cm'] != null
              ? double.tryParse(map['altura_cm'].toString())
              : null,
      telefono: map['telefono']?.toString(),
      fechaInicioPrograma: fechaInicioParsed,
      objetivoPrincipal: map['objetivo_principal']?.toString(),
      objetivoSecundario: map['objetivo_secundario']?.toString(),
    );
  }

  Asesorado copyWith({
    int? coachId,
    String? name,
    String? avatarUrl,
    AsesoradoStatus? status,
    int? planId,
    String? planName,
    DateTime? dueDate,
    DateTime? fechaNacimiento,
    String? sexo,
    double? alturaCm,
    String? telefono,
    DateTime? fechaInicioPrograma,
    String? objetivoPrincipal,
    String? objetivoSecundario,
  }) {
    return Asesorado(
      id: id,
      coachId: coachId ?? this.coachId,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      dueDate: dueDate ?? this.dueDate,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      sexo: sexo ?? this.sexo,
      alturaCm: alturaCm ?? this.alturaCm,
      telefono: telefono ?? this.telefono,
      fechaInicioPrograma: fechaInicioPrograma ?? this.fechaInicioPrograma,
      objetivoPrincipal: objetivoPrincipal ?? this.objetivoPrincipal,
      objetivoSecundario: objetivoSecundario ?? this.objetivoSecundario,
    );
  }
}
