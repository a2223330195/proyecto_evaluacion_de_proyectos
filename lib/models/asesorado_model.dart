// lib/models/asesorado_model.dart

enum AsesoradoStatus { activo, enPausa, deudor }

class Asesorado {
  final int id;
  final int? coachId;
  final String name;
  final String avatarUrl;
  final AsesoradoStatus status;
  final int? planId;
  final String? planName;
  final DateTime? dueDate;
  final int? edad;
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
    this.edad,
    this.sexo,
    this.alturaCm,
    this.telefono,
    this.fechaInicioPrograma,
    this.objetivoPrincipal,
    this.objetivoSecundario,
  });

  factory Asesorado.fromMap(Map<String, dynamic> map) {
    final fechaVencimiento = map['fecha_vencimiento'];
    final fechaInicio = map['fecha_inicio_programa'];

    DateTime? dueDateParsed;
    if (fechaVencimiento != null) {
      dueDateParsed = DateTime.tryParse(fechaVencimiento.toString());
    }

    DateTime? fechaInicioParsed;
    if (fechaInicio != null) {
      fechaInicioParsed = DateTime.tryParse(fechaInicio.toString());
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
      edad: map['edad'] != null ? int.tryParse(map['edad'].toString()) : null,
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
    int? edad,
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
      edad: edad ?? this.edad,
      sexo: sexo ?? this.sexo,
      alturaCm: alturaCm ?? this.alturaCm,
      telefono: telefono ?? this.telefono,
      fechaInicioPrograma: fechaInicioPrograma ?? this.fechaInicioPrograma,
      objetivoPrincipal: objetivoPrincipal ?? this.objetivoPrincipal,
      objetivoSecundario: objetivoSecundario ?? this.objetivoSecundario,
    );
  }
}
