import 'package:equatable/equatable.dart';

/// Representa una sesión agendada en la agenda diaria del coach.
class AgendaSession extends Equatable {
  final int id;
  final String status;
  final String horaAsignada;
  final int asesoradoId;
  final String asesoradoNombre;
  final String rutinaNombre;

  const AgendaSession({
    required this.id,
    required this.status,
    required this.horaAsignada,
    required this.asesoradoId,
    required this.asesoradoNombre,
    required this.rutinaNombre,
  });

  bool get isCompleted => status == 'completada';

  AgendaSession copyWith({
    String? status,
    String? horaAsignada,
    int? asesoradoId,
    String? asesoradoNombre,
    String? rutinaNombre,
  }) {
    return AgendaSession(
      id: id,
      status: status ?? this.status,
      horaAsignada: horaAsignada ?? this.horaAsignada,
      asesoradoId: asesoradoId ?? this.asesoradoId,
      asesoradoNombre: asesoradoNombre ?? this.asesoradoNombre,
      rutinaNombre: rutinaNombre ?? this.rutinaNombre,
    );
  }

  @override
  List<Object?> get props => [
    id,
    status,
    horaAsignada,
    asesoradoId,
    asesoradoNombre,
    rutinaNombre,
  ];
}

/// Métricas resumidas para la semana actual del dashboard.
class WeeklySummary extends Equatable {
  final int asesoradosActivos;
  final int sesionesCompletadas;
  final int sesionesTotales;
  final double porcentajeCompletado;
  final double porcentajeAsistencia;

  const WeeklySummary({
    required this.asesoradosActivos,
    required this.sesionesCompletadas,
    required this.sesionesTotales,
    required this.porcentajeCompletado,
    required this.porcentajeAsistencia,
  });

  WeeklySummary copyWith({
    int? asesoradosActivos,
    int? sesionesCompletadas,
    int? sesionesTotales,
    double? porcentajeCompletado,
    double? porcentajeAsistencia,
  }) {
    return WeeklySummary(
      asesoradosActivos: asesoradosActivos ?? this.asesoradosActivos,
      sesionesCompletadas: sesionesCompletadas ?? this.sesionesCompletadas,
      sesionesTotales: sesionesTotales ?? this.sesionesTotales,
      porcentajeCompletado: porcentajeCompletado ?? this.porcentajeCompletado,
      porcentajeAsistencia: porcentajeAsistencia ?? this.porcentajeAsistencia,
    );
  }

  static const zero = WeeklySummary(
    asesoradosActivos: 0,
    sesionesCompletadas: 0,
    sesionesTotales: 0,
    porcentajeCompletado: 0,
    porcentajeAsistencia: 0,
  );

  @override
  List<Object?> get props => [
    asesoradosActivos,
    sesionesCompletadas,
    sesionesTotales,
    porcentajeCompletado,
    porcentajeAsistencia,
  ];
}

/// Actividad reciente del dashboard (ej. sesiones completadas recientemente).
class DashboardActivity extends Equatable {
  final String asesoradoNombre;
  final String rutinaNombre;
  final DateTime timestamp;

  const DashboardActivity({
    required this.asesoradoNombre,
    required this.rutinaNombre,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [asesoradoNombre, rutinaNombre, timestamp];
}
