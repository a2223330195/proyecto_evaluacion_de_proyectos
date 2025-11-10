import 'package:equatable/equatable.dart';

/// Eventos para el bloc de pagos pendientes
abstract class PagosPendientesEvent extends Equatable {
  const PagosPendientesEvent();

  @override
  List<Object?> get props => [];
}

/// Evento: Cargar pagos pendientes del coach
class CargarPagosPendientes extends PagosPendientesEvent {
  final int coachId;
  final int pageNumber;
  final String? filtroEstado; // 'todos', 'pendiente', 'atrasado', 'proximo'
  final String? searchQuery;

  const CargarPagosPendientes(
    this.coachId, {
    this.pageNumber = 1,
    this.filtroEstado,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [coachId, pageNumber, filtroEstado, searchQuery];
}

/// Evento: Actualizar filtro por estado
class FiltrarPagosPendientes extends PagosPendientesEvent {
  final String estado;

  const FiltrarPagosPendientes(this.estado);

  @override
  List<Object> get props => [estado];
}

/// Evento: Buscar en la lista de pagos pendientes
class BuscarEnPagosPendientes extends PagosPendientesEvent {
  final String query;

  const BuscarEnPagosPendientes(this.query);

  @override
  List<Object> get props => [query];
}

/// Evento: Cambiar página en resultados paginados
class CambiarPaginaPagosPendientes extends PagosPendientesEvent {
  final int page;

  const CambiarPaginaPagosPendientes(this.page);

  @override
  List<Object> get props => [page];
}

/// Evento: Registrar un abono directo desde la vista de pendientes
class RegistrarAbonoPendiente extends PagosPendientesEvent {
  final int coachId;
  final int asesoradoId;
  final double monto;
  final String? nota;

  const RegistrarAbonoPendiente({
    required this.coachId,
    required this.asesoradoId,
    required this.monto,
    this.nota,
  });

  @override
  List<Object?> get props => [coachId, asesoradoId, monto, nota];
}

/// Evento: Completar un pago desde la vista de pendientes
class CompletarPagoPendiente extends PagosPendientesEvent {
  final int coachId;
  final int asesoradoId;
  final double monto;
  final String? nota;

  const CompletarPagoPendiente({
    required this.coachId,
    required this.asesoradoId,
    required this.monto,
    this.nota,
  });

  @override
  List<Object?> get props => [coachId, asesoradoId, monto, nota];
}
