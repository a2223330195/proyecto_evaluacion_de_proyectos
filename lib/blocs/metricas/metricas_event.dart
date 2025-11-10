// lib/blocs/metricas/metricas_event.dart

import 'package:equatable/equatable.dart';

abstract class MetricasEvent extends Equatable {
  const MetricasEvent();

  @override
  List<Object?> get props => [];
}

/// Evento: Cargar historial de mediciones para una ficha de asesorado
class LoadMedicionesDetalle extends MetricasEvent {
  final int asesoradoId;
  final int rangeLimit; // 5, 10, 30, 0 (all)

  const LoadMedicionesDetalle(this.asesoradoId, {this.rangeLimit = 5});

  @override
  List<Object> get props => [asesoradoId, rangeLimit];
}

/// Evento: Cargar más mediciones (infinite scroll)
class LoadMoreMediciones extends MetricasEvent {
  const LoadMoreMediciones();

  @override
  List<Object> get props => [];
}

/// Evento: Crear una nueva medición
class CrearMedicion extends MetricasEvent {
  final int asesoradoId;
  final DateTime fechaMedicion;
  final double? peso;
  final double? porcentajeGrasa;
  final double? imc;
  final double? masaMuscular;
  final double? aguaCorporal;
  final double? pechoCm;
  final double? cinturaCm;
  final double? caderaCm;
  final double? brazoIzqCm;
  final double? brazoDerCm;
  final double? piernaIzqCm;
  final double? piernaDerCm;
  final double? pantorrillaIzqCm;
  final double? pantorrillaDerCm;
  final double? frecuenciaCardiaca;
  final double? recordResistencia;

  const CrearMedicion({
    required this.asesoradoId,
    required this.fechaMedicion,
    this.peso,
    this.porcentajeGrasa,
    this.imc,
    this.masaMuscular,
    this.aguaCorporal,
    this.pechoCm,
    this.cinturaCm,
    this.caderaCm,
    this.brazoIzqCm,
    this.brazoDerCm,
    this.piernaIzqCm,
    this.piernaDerCm,
    this.pantorrillaIzqCm,
    this.pantorrillaDerCm,
    this.frecuenciaCardiaca,
    this.recordResistencia,
  });

  @override
  List<Object?> get props => [
    asesoradoId,
    fechaMedicion,
    peso,
    porcentajeGrasa,
    imc,
    masaMuscular,
    aguaCorporal,
    pechoCm,
    cinturaCm,
    caderaCm,
    brazoIzqCm,
    brazoDerCm,
    piernaIzqCm,
    piernaDerCm,
    pantorrillaIzqCm,
    pantorrillaDerCm,
    frecuenciaCardiaca,
    recordResistencia,
  ];
}

/// Evento: Actualizar una medición existente
class ActualizarMedicion extends MetricasEvent {
  final int medicionId;
  final int asesoradoId;
  final DateTime fechaMedicion;
  final double? peso;
  final double? porcentajeGrasa;
  final double? imc;
  final double? masaMuscular;
  final double? aguaCorporal;
  final double? pechoCm;
  final double? cinturaCm;
  final double? caderaCm;
  final double? brazoIzqCm;
  final double? brazoDerCm;
  final double? piernaIzqCm;
  final double? piernaDerCm;
  final double? pantorrillaIzqCm;
  final double? pantorrillaDerCm;
  final double? frecuenciaCardiaca;
  final double? recordResistencia;

  const ActualizarMedicion({
    required this.medicionId,
    required this.asesoradoId,
    required this.fechaMedicion,
    this.peso,
    this.porcentajeGrasa,
    this.imc,
    this.masaMuscular,
    this.aguaCorporal,
    this.pechoCm,
    this.cinturaCm,
    this.caderaCm,
    this.brazoIzqCm,
    this.brazoDerCm,
    this.piernaIzqCm,
    this.piernaDerCm,
    this.pantorrillaIzqCm,
    this.pantorrillaDerCm,
    this.frecuenciaCardiaca,
    this.recordResistencia,
  });

  @override
  List<Object?> get props => [
    medicionId,
    asesoradoId,
    fechaMedicion,
    peso,
    porcentajeGrasa,
    imc,
    masaMuscular,
    aguaCorporal,
    pechoCm,
    cinturaCm,
    caderaCm,
    brazoIzqCm,
    brazoDerCm,
    piernaIzqCm,
    piernaDerCm,
    pantorrillaIzqCm,
    pantorrillaDerCm,
    frecuenciaCardiaca,
    recordResistencia,
  ];
}

/// Evento: Eliminar una medición
class EliminarMedicion extends MetricasEvent {
  final int medicionId;
  final int asesoradoId;

  const EliminarMedicion({required this.medicionId, required this.asesoradoId});

  @override
  List<Object> get props => [medicionId, asesoradoId];
}
