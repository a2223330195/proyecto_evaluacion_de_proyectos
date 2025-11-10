import 'package:coachhub/models/asesorado_pago_pendiente.dart';
import 'package:equatable/equatable.dart';

// --- ESTADOS BASE ---
abstract class PagosPendientesState extends Equatable {
  const PagosPendientesState();

  @override
  List<Object?> get props => [];
}

class PagosPendientesInitial extends PagosPendientesState {
  const PagosPendientesInitial();
}

class PagosPendientesLoading extends PagosPendientesState {
  const PagosPendientesLoading();
}

class PagosPendientesError extends PagosPendientesState {
  final String message;

  const PagosPendientesError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Estado: Pagos pendientes por asesorado cargados (Fase E.3)
class PagosPendientesLoaded extends PagosPendientesState {
  final List<AsesoradoPagoPendiente> asesoradosConPago;
  final List<AsesoradoPagoPendiente> allAsesorados;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final String? filtroEstado; // 'todos', 'pendiente', 'atrasado', 'proximo'
  final String? searchQuery;
  final double totalMontoPendiente;

  const PagosPendientesLoaded({
    required this.asesoradosConPago,
    required this.allAsesorados,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    this.filtroEstado,
    this.searchQuery,
    required this.totalMontoPendiente,
  });

  /// Método copyWith para actualizaciones inmutables
  PagosPendientesLoaded copyWith({
    List<AsesoradoPagoPendiente>? asesoradosConPago,
    List<AsesoradoPagoPendiente>? allAsesorados,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    String? filtroEstado,
    String? searchQuery,
    double? totalMontoPendiente,
  }) {
    return PagosPendientesLoaded(
      asesoradosConPago: asesoradosConPago ?? this.asesoradosConPago,
      allAsesorados: allAsesorados ?? this.allAsesorados,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      filtroEstado: filtroEstado ?? this.filtroEstado,
      searchQuery: searchQuery ?? this.searchQuery,
      totalMontoPendiente: totalMontoPendiente ?? this.totalMontoPendiente,
    );
  }

  @override
  List<Object?> get props => [
    asesoradosConPago,
    allAsesorados,
    currentPage,
    totalPages,
    totalCount,
    filtroEstado,
    searchQuery,
    totalMontoPendiente,
  ];
}
