import 'package:coachhub/models/asesorado_model.dart';
import 'package:coachhub/models/dashboard_models.dart';
import 'package:equatable/equatable.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardData data;
  final bool isRefreshing;
  final DateTime lastUpdated;

  const DashboardLoaded({
    required this.data,
    this.isRefreshing = false,
    required this.lastUpdated,
  });

  DashboardLoaded copyWith({
    DashboardData? data,
    bool? isRefreshing,
    DateTime? lastUpdated,
  }) {
    return DashboardLoaded(
      data: data ?? this.data,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [data, isRefreshing, lastUpdated];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Agrupa todos los datos necesarios para renderizar el dashboard.
class DashboardData extends Equatable {
  final int totalAsesorados;
  final int deudores;
  final int activos;
  final int enPausa;
  final double ingresosMensuales;
  final List<Asesorado> asesoradosProximos;
  final List<AgendaSession> agendaHoy;
  final WeeklySummary resumenSemanal;
  final List<Asesorado> deudoresListado;
  final List<DashboardActivity> actividadReciente;

  const DashboardData({
    required this.totalAsesorados,
    required this.deudores,
    required this.activos,
    required this.enPausa,
    required this.ingresosMensuales,
    required this.asesoradosProximos,
    required this.agendaHoy,
    required this.resumenSemanal,
    required this.deudoresListado,
    required this.actividadReciente,
  });

  DashboardData copyWith({
    int? totalAsesorados,
    int? deudores,
    int? activos,
    int? enPausa,
    double? ingresosMensuales,
    List<Asesorado>? asesoradosProximos,
    List<AgendaSession>? agendaHoy,
    WeeklySummary? resumenSemanal,
    List<Asesorado>? deudoresListado,
    List<DashboardActivity>? actividadReciente,
  }) {
    return DashboardData(
      totalAsesorados: totalAsesorados ?? this.totalAsesorados,
      deudores: deudores ?? this.deudores,
      activos: activos ?? this.activos,
      enPausa: enPausa ?? this.enPausa,
      ingresosMensuales: ingresosMensuales ?? this.ingresosMensuales,
      asesoradosProximos: asesoradosProximos ?? this.asesoradosProximos,
      agendaHoy: agendaHoy ?? this.agendaHoy,
      resumenSemanal: resumenSemanal ?? this.resumenSemanal,
      deudoresListado: deudoresListado ?? this.deudoresListado,
      actividadReciente: actividadReciente ?? this.actividadReciente,
    );
  }

  static DashboardData empty() => const DashboardData(
    totalAsesorados: 0,
    deudores: 0,
    activos: 0,
    enPausa: 0,
    ingresosMensuales: 0,
    asesoradosProximos: [],
    agendaHoy: [],
    resumenSemanal: WeeklySummary.zero,
    deudoresListado: [],
    actividadReciente: [],
  );

  @override
  List<Object?> get props => [
    totalAsesorados,
    deudores,
    activos,
    enPausa,
    ingresosMensuales,
    asesoradosProximos,
    agendaHoy,
    resumenSemanal,
    deudoresListado,
    actividadReciente,
  ];
}
