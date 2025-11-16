import 'package:equatable/equatable.dart';
import '../../models/pago_membresia_model.dart';

/// Estados para PagosBloc
abstract class PagosState extends Equatable {
  const PagosState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class PagosInitial extends PagosState {
  const PagosInitial();
}

/// Estado: Cargando pagos
class PagosLoading extends PagosState {
  const PagosLoading();
}

/// Estado: Pagos cargados exitosamente
class PagosLoaded extends PagosState {
  final List<PagoMembresia> pagos;
  final int currentPage;
  final int totalPages;
  final String? searchQuery;
  final bool isLoading;
  final double totalAmount;

  // 🛡️ MÓDULO 4: Error Handling - Soporte para fallback offline
  final bool fromCache;
  final String? errorMessage;

  // 🛡️ MÓDULO 5 FASE 5.6: Infinite scroll
  final bool hasMore;

  // 🎯 MÓDULO 1 TAREA 1.2: Feedback visual - Mensaje para SnackBar
  final String? feedbackMessage;

  const PagosLoaded({
    required this.pagos,
    required this.currentPage,
    required this.totalPages,
    this.searchQuery,
    this.isLoading = false,
    required this.totalAmount,
    this.fromCache = false,
    this.errorMessage,
    this.hasMore = true,
    this.feedbackMessage,
  });

  /// Método copyWith para actualizaciones inmutables del estado
  PagosLoaded copyWith({
    List<PagoMembresia>? pagos,
    int? currentPage,
    int? totalPages,
    String? searchQuery,
    bool? isLoading,
    double? totalAmount,
    bool? fromCache,
    String? errorMessage,
    bool? hasMore,
    String? feedbackMessage,
  }) {
    return PagosLoaded(
      pagos: pagos ?? this.pagos,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      totalAmount: totalAmount ?? this.totalAmount,
      fromCache: fromCache ?? this.fromCache,
      errorMessage: errorMessage ?? this.errorMessage,
      hasMore: hasMore ?? this.hasMore,
      feedbackMessage: feedbackMessage ?? this.feedbackMessage,
    );
  }

  @override
  List<Object?> get props => [
    pagos,
    currentPage,
    totalPages,
    searchQuery,
    isLoading,
    totalAmount,
    fromCache,
    errorMessage,
    hasMore,
    feedbackMessage,
  ];
}

/// Estado: Error al cargar pagos
class PagosError extends PagosState {
  final String message;

  // 🛡️ MÓDULO 4: Error Handling - Soporte para retry
  final bool isNetworkError;
  final bool canRetry;

  const PagosError(
    this.message, {
    this.isNetworkError = false,
    this.canRetry = false,
  });

  @override
  List<Object> get props => [message, isNetworkError, canRetry];
}

/// Estado: Pago eliminado
class PagoDeleted extends PagosState {
  final String message;

  const PagoDeleted(this.message);

  @override
  List<Object> get props => [message];
}

/// Estado: Pago creado/actualizado
class PagoCreatedOrUpdated extends PagosState {
  final String message;

  const PagoCreatedOrUpdated(this.message);

  @override
  List<Object> get props => [message];
}

/// Estado: Abono registrado exitosamente (nuevo)
class AbonoRegistrado extends PagosState {
  final double saldoPendiente;
  final double totalAbonado;
  final String periodo;

  const AbonoRegistrado({
    required this.saldoPendiente,
    required this.totalAbonado,
    required this.periodo,
  });

  @override
  List<Object> get props => [saldoPendiente, totalAbonado, periodo];
}

/// Estado: Pago completado (nuevo)
class PagoCompletado extends PagosState {
  final String periodo;
  final double montoTotal;

  const PagoCompletado({required this.periodo, required this.montoTotal});

  @override
  List<Object> get props => [periodo, montoTotal];
}

/// Estado: Estatus de pago obtenido (nuevo)
class EstatusPageObtenido extends PagosState {
  final String estado; // "activo", "pendiente", "deudor"
  final double saldoPendiente;
  final DateTime? fechaVencimiento;
  final String? planNombre;
  final double? costoPlan;
  final String? periodoSugerido;
  final double totalAbonadoPeriodo;

  const EstatusPageObtenido({
    required this.estado,
    required this.saldoPendiente,
    this.fechaVencimiento,
    this.planNombre,
    this.costoPlan,
    this.periodoSugerido,
    this.totalAbonadoPeriodo = 0.0,
  });

  @override
  List<Object?> get props => [
    estado,
    saldoPendiente,
    fechaVencimiento,
    planNombre,
    costoPlan,
    periodoSugerido,
    totalAbonadoPeriodo,
  ];
}

/// Estado: Detalles completos de pagos cargados (para ficha de asesorado)
class PagosDetallesCargados extends PagosState {
  final String estado; // "activo", "pendiente", "deudor"
  final double saldoPendiente;
  final DateTime? fechaVencimiento;
  final String? planNombre;
  final double? costoPlan;
  final String? periodoSugerido;
  final double totalAbonadoPeriodo;
  final List<PagoMembresia>
  pagos; // Historial filtrado actual (por período seleccionado)
  final List<PagoMembresia>
  todosPagos; // 🎯 NUEVA: Historial COMPLETO (sin filtrar) para restauración
  final int currentPage;
  final int totalPages;
  final double totalAmount; // Total de pagos históricos
  final String?
  feedbackMessage; // 🔧 Nuevo: mensaje de feedback para mostrar SnackBar
  final List<String>
  periodosDisponibles; // 🎯 NUEVA: Períodos disponibles para seleccionar (TODOS, no solo pendientes)
  final String?
  periodoSeleccionado; // 🎯 NUEVA: Período actualmente seleccionado (null = todos)
  final String? ultimoPeriodoPagado; // Último período cubierto
  final bool
  puedePagarAnticipado; // Si puede pagar el siguiente período aunque no sea obligatorio
  final bool
  enVentanaCorte; // Si está dentro de la ventana de corte (mostrar alerta preventiva)

  const PagosDetallesCargados({
    required this.estado,
    required this.saldoPendiente,
    this.fechaVencimiento,
    this.planNombre,
    this.costoPlan,
    this.periodoSugerido,
    this.totalAbonadoPeriodo = 0.0,
    required this.pagos,
    required this.todosPagos, // 🎯 NUEVA: parámetro requerido
    required this.currentPage,
    required this.totalPages,
    required this.totalAmount,
    this.feedbackMessage,
    this.periodosDisponibles = const [],
    this.periodoSeleccionado,
    this.ultimoPeriodoPagado,
    this.puedePagarAnticipado = false,
    this.enVentanaCorte = false,
  });

  /// Método copyWith para actualizaciones inmutables
  PagosDetallesCargados copyWith({
    String? estado,
    double? saldoPendiente,
    DateTime? fechaVencimiento,
    String? planNombre,
    double? costoPlan,
    String? periodoSugerido,
    double? totalAbonadoPeriodo,
    List<PagoMembresia>? pagos,
    List<PagoMembresia>? todosPagos,
    int? currentPage,
    int? totalPages,
    double? totalAmount,
    String? feedbackMessage,
    List<String>? periodosDisponibles,
    String? periodoSeleccionado,
    String? ultimoPeriodoPagado,
    bool? puedePagarAnticipado,
    bool? enVentanaCorte,
  }) {
    return PagosDetallesCargados(
      estado: estado ?? this.estado,
      saldoPendiente: saldoPendiente ?? this.saldoPendiente,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      planNombre: planNombre ?? this.planNombre,
      costoPlan: costoPlan ?? this.costoPlan,
      periodoSugerido: periodoSugerido ?? this.periodoSugerido,
      totalAbonadoPeriodo: totalAbonadoPeriodo ?? this.totalAbonadoPeriodo,
      pagos: pagos ?? this.pagos,
      todosPagos: todosPagos ?? this.todosPagos,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalAmount: totalAmount ?? this.totalAmount,
      feedbackMessage: feedbackMessage ?? this.feedbackMessage,
      periodosDisponibles: periodosDisponibles ?? this.periodosDisponibles,
      periodoSeleccionado: periodoSeleccionado ?? this.periodoSeleccionado,
      ultimoPeriodoPagado: ultimoPeriodoPagado ?? this.ultimoPeriodoPagado,
      puedePagarAnticipado: puedePagarAnticipado ?? this.puedePagarAnticipado,
      enVentanaCorte: enVentanaCorte ?? this.enVentanaCorte,
    );
  }

  @override
  List<Object?> get props => [
    estado,
    saldoPendiente,
    fechaVencimiento,
    planNombre,
    costoPlan,
    periodoSugerido,
    totalAbonadoPeriodo,
    pagos,
    todosPagos,
    currentPage,
    totalPages,
    totalAmount,
    feedbackMessage,
    periodosDisponibles,
    periodoSeleccionado,
    ultimoPeriodoPagado,
    puedePagarAnticipado,
    enVentanaCorte,
  ];
}
