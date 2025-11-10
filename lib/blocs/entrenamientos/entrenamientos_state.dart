import 'package:equatable/equatable.dart';
import 'package:coachhub/models/asignacion_model.dart';

abstract class EntrenamientosState extends Equatable {
  const EntrenamientosState();

  @override
  List<Object?> get props => [];
}

class EntrenamientosInitial extends EntrenamientosState {
  const EntrenamientosInitial();
}

class EntrenamientosLoading extends EntrenamientosState {
  const EntrenamientosLoading();
}

class EntrenamientosLoaded extends EntrenamientosState {
  final List<Asignacion> entrenamientos;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final bool isLoading;

  const EntrenamientosLoaded(
    this.entrenamientos, {
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = true,
    this.isLoading = false,
  });

  EntrenamientosLoaded copyWith({
    List<Asignacion>? entrenamientos,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
    bool? isLoading,
  }) {
    return EntrenamientosLoaded(
      entrenamientos ?? this.entrenamientos,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
    entrenamientos,
    currentPage,
    totalPages,
    hasMore,
    isLoading,
  ];
}

class EntrenamientosError extends EntrenamientosState {
  final String message;

  const EntrenamientosError(this.message);

  @override
  List<Object> get props => [message];
}
