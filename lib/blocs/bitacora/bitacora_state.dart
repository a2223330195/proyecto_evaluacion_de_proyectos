// lib/blocs/bitacora/bitacora_state.dart

import 'package:equatable/equatable.dart';
import '../../models/nota_model.dart';

abstract class BitacoraState extends Equatable {
  const BitacoraState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class BitacoraInitial extends BitacoraState {
  const BitacoraInitial();
}

/// Estado: Cargando notas
class BitacoraLoading extends BitacoraState {
  const BitacoraLoading();
}

/// Estado: Todas las notas cargadas (para bitácora completa)
class TodasLasNotasLoaded extends BitacoraState {
  final List<Nota> notas;
  final int currentPage;
  final int totalPages;
  final String? feedbackMessage;

  const TodasLasNotasLoaded({
    required this.notas,
    required this.currentPage,
    required this.totalPages,
    this.feedbackMessage,
  });

  @override
  List<Object?> get props => [notas, currentPage, totalPages, feedbackMessage];
}

/// Estado: Solo notas prioritarias cargadas
class NotasPrioritariasLoaded extends BitacoraState {
  final List<Nota> notas;

  const NotasPrioritariasLoaded(this.notas);

  @override
  List<Object> get props => [notas];
}

/// Estado: Notas prioritarias del dashboard cargadas (de todos los asesorados)
class NotasPrioritariasDashboardLoaded extends BitacoraState {
  final List<Nota> notas;

  const NotasPrioritariasDashboardLoaded(this.notas);

  @override
  List<Object> get props => [notas];
}

/// Estado: Nota creada
class NotaCreada extends BitacoraState {
  final String message;

  const NotaCreada(this.message);

  @override
  List<Object> get props => [message];
}

/// Estado: Nota actualizada
class NotaActualizada extends BitacoraState {
  final String message;

  const NotaActualizada(this.message);

  @override
  List<Object> get props => [message];
}

/// Estado: Nota eliminada
class NotaEliminada extends BitacoraState {
  final String message;

  const NotaEliminada(this.message);

  @override
  List<Object> get props => [message];
}

/// Estado: Resultados de búsqueda
class ResultadosBusqueda extends BitacoraState {
  final List<Nota> notas;

  const ResultadosBusqueda(this.notas);

  @override
  List<Object> get props => [notas];
}

/// Estado: Error
class BitacoraError extends BitacoraState {
  final String message;

  const BitacoraError(this.message);

  @override
  List<Object> get props => [message];
}
