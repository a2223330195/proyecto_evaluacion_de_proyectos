// lib/blocs/metricas/metricas_state.dart

import 'package:equatable/equatable.dart';
import '../../models/medicion_model.dart';

abstract class MetricasState extends Equatable {
  const MetricasState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class MetricasInitial extends MetricasState {
  const MetricasInitial();
}

/// Estado: Cargando métricas
class MetricasLoading extends MetricasState {
  const MetricasLoading();
}

/// Estado: Error
class MetricasError extends MetricasState {
  final String message;

  const MetricasError(this.message);

  @override
  List<Object> get props => [message];
}

/// Estado: Detalles de mediciones cargados (para pantalla de detalle)
class MedicionesDetallesCargados extends MetricasState {
  /// Lista de mediciones ordenadas ASC por fecha (para gráficos)
  final List<Medicion> medicionesParaGrafico;

  /// Lista de mediciones ordenadas DESC por fecha (para lista UI)
  final List<Medicion> medicionesParaLista;

  final Medicion? ultimaMedicion;
  final int rangeLimit;
  final String? feedbackMessage;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final bool isLoading;

  const MedicionesDetallesCargados({
    required this.medicionesParaGrafico,
    required this.medicionesParaLista,
    this.ultimaMedicion,
    required this.rangeLimit,
    this.feedbackMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = true,
    this.isLoading = false,
  });

  @override
  List<Object?> get props => [
    medicionesParaGrafico,
    medicionesParaLista,
    ultimaMedicion,
    rangeLimit,
    feedbackMessage,
    currentPage,
    totalPages,
    hasMore,
    isLoading,
  ];

  MedicionesDetallesCargados copyWith({
    List<Medicion>? medicionesParaGrafico,
    List<Medicion>? medicionesParaLista,
    Medicion? ultimaMedicion,
    int? rangeLimit,
    String? feedbackMessage,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
    bool? isLoading,
  }) {
    return MedicionesDetallesCargados(
      medicionesParaGrafico:
          medicionesParaGrafico ?? this.medicionesParaGrafico,
      medicionesParaLista: medicionesParaLista ?? this.medicionesParaLista,
      ultimaMedicion: ultimaMedicion ?? this.ultimaMedicion,
      rangeLimit: rangeLimit ?? this.rangeLimit,
      feedbackMessage: feedbackMessage ?? this.feedbackMessage,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
