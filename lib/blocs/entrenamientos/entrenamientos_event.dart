import 'package:equatable/equatable.dart';

abstract class EntrenamientosEvent extends Equatable {
  const EntrenamientosEvent();

  @override
  List<Object?> get props => [];
}

class LoadEntrenamientos extends EntrenamientosEvent {
  final int asesoradoId;
  final int limit;
  final bool forceRefresh;

  const LoadEntrenamientos(
    this.asesoradoId, {
    this.limit = 8,
    this.forceRefresh = false,
  });

  @override
  List<Object> get props => [asesoradoId, limit, forceRefresh];
}

class LoadMoreEntrenamientos extends EntrenamientosEvent {
  const LoadMoreEntrenamientos();

  @override
  List<Object> get props => [];
}
