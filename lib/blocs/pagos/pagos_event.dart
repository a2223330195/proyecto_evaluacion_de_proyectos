import 'package:equatable/equatable.dart';

/// Eventos para PagosBloc
abstract class PagosEvent extends Equatable {
  const PagosEvent();

  @override
  List<Object?> get props => [];
}

/// Evento: Cargar pagos paginados para un asesorado
class LoadPagos extends PagosEvent {
  final int asesoradoId;
  final int pageNumber;
  final String? searchQuery;

  const LoadPagos(this.asesoradoId, this.pageNumber, this.searchQuery);

  @override
  List<Object?> get props => [asesoradoId, pageNumber, searchQuery];
}

/// Evento: Ir a siguiente página
class NextPage extends PagosEvent {
  const NextPage();
}

/// Evento: Ir a página anterior
class PreviousPage extends PagosEvent {
  const PreviousPage();
}

/// Evento: Eliminar pago
class DeletePago extends PagosEvent {
  final int pagoId;

  const DeletePago(this.pagoId);

  @override
  List<Object> get props => [pagoId];
}

/// Evento: Refrescar lista
class RefreshPagos extends PagosEvent {
  const RefreshPagos();
}

/// Evento: Crear nuevo pago
class CreatePago extends PagosEvent {
  final int asesoradoId;
  final DateTime fechaPago;
  final double monto;
  final String? nota;

  const CreatePago(this.asesoradoId, this.fechaPago, this.monto, [this.nota]);

  @override
  List<Object?> get props => [asesoradoId, fechaPago, monto, nota];
}

/// Evento: Actualizar pago existente
class UpdatePago extends PagosEvent {
  final int pagoId;
  final DateTime fechaPago;
  final double monto;
  final String? nota;

  const UpdatePago(this.pagoId, this.fechaPago, this.monto, [this.nota]);

  @override
  List<Object?> get props => [pagoId, fechaPago, monto, nota];
}

/// Evento: Registrar abono parcial (nuevo)
class RecordarAbono extends PagosEvent {
  final int asesoradoId;
  final double monto;
  final String? nota;

  const RecordarAbono(this.asesoradoId, this.monto, this.nota);

  @override
  List<Object?> get props => [asesoradoId, monto, nota];
}

/// Evento: Completar pago completo (nuevo)
class CompletarPago extends PagosEvent {
  final int asesoradoId;
  final double monto;
  final String? nota;

  const CompletarPago(this.asesoradoId, this.monto, this.nota);

  @override
  List<Object?> get props => [asesoradoId, monto, nota];
}

/// Evento: Obtener estado del pago (nuevo)
class ObtenerEstadoPago extends PagosEvent {
  final int asesoradoId;

  const ObtenerEstadoPago(this.asesoradoId);

  @override
  List<Object> get props => [asesoradoId];
}

/// Evento: Cargar detalles completos de pagos para una ficha de asesorado
class LoadPagosDetails extends PagosEvent {
  final int asesoradoId;

  const LoadPagosDetails(this.asesoradoId);

  @override
  List<Object> get props => [asesoradoId];
}

/// Evento: Cambiar criterio de ordenamiento (por fecha o por periodo)
class OrdenarPagosPorPeriodo extends PagosEvent {
  final int asesoradoId;
  final bool porPeriodo; // true = orden por periodo, false = orden por fecha

  const OrdenarPagosPorPeriodo(this.asesoradoId, this.porPeriodo);

  @override
  List<Object> get props => [asesoradoId, porPeriodo];
}

/// 🛡️ MÓDULO 5 FASE 5.6: Cargar más pagos (infinite scroll)
/// Append mode: agrega items a la lista existente
class LoadMorePagos extends PagosEvent {
  const LoadMorePagos();
}
