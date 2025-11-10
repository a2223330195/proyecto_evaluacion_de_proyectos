import 'package:equatable/equatable.dart';
import '../../models/asesorado_model.dart';

/// Estados para AsesoradosBloc
abstract class AsesoradosState extends Equatable {
  const AsesoradosState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class AsesoradosInitial extends AsesoradosState {
  const AsesoradosInitial();
}

/// Estado: Cargando
class AsesoradosLoading extends AsesoradosState {
  const AsesoradosLoading();
}

/// Estado: Cargado exitosamente
class AsesoradosLoaded extends AsesoradosState {
  final List<Asesorado> asesorados;
  final int currentPage;
  final int totalPages;
  final String? searchQuery;
  final bool isLoading;
  final bool hasMore; // 🛡️ MÓDULO 5: Para infinite scroll

  const AsesoradosLoaded({
    required this.asesorados,
    required this.currentPage,
    required this.totalPages,
    this.searchQuery,
    this.isLoading = false,
    this.hasMore = true, // 🛡️ MÓDULO 5
  });

  /// Copiar con cambios opcionales
  AsesoradosLoaded copyWith({
    List<Asesorado>? asesorados,
    int? currentPage,
    int? totalPages,
    String? searchQuery,
    bool? isLoading,
    bool? hasMore, // 🛡️ MÓDULO 5
  }) {
    return AsesoradosLoaded(
      asesorados: asesorados ?? this.asesorados,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore, // 🛡️ MÓDULO 5
    );
  }

  @override
  List<Object?> get props => [
    asesorados,
    currentPage,
    totalPages,
    searchQuery,
    isLoading,
    hasMore, // 🛡️ MÓDULO 5
  ];
}

/// Estado: Error
class AsesoradosError extends AsesoradosState {
  final String message;

  const AsesoradosError(this.message);

  @override
  List<Object> get props => [message];
}

/// Estado: Asesorado eliminado
class AsesoradoDeleted extends AsesoradosState {
  final String message;

  const AsesoradoDeleted(this.message);

  @override
  List<Object> get props => [message];
}
