import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:coachhub/models/asignacion_model.dart';
import 'package:coachhub/services/entrenamiento_service.dart';
import 'entrenamientos_event.dart';
import 'entrenamientos_state.dart';

class EntrenamientosBloc
    extends Bloc<EntrenamientosEvent, EntrenamientosState> {
  final EntrenamientoService _service;
  List<Asignacion>? _cache;
  int _currentAsesoradoId = 0;

  EntrenamientosBloc({EntrenamientoService? service})
    : _service = service ?? EntrenamientoService(),
      super(const EntrenamientosInitial()) {
    on<LoadEntrenamientos>(_onLoadEntrenamientos);
    on<LoadMoreEntrenamientos>(_onLoadMoreEntrenamientos);
  }

  Future<void> _onLoadEntrenamientos(
    LoadEntrenamientos event,
    Emitter<EntrenamientosState> emit,
  ) async {
    _currentAsesoradoId = event.asesoradoId;

    if (_cache != null && !event.forceRefresh) {
      emit(EntrenamientosLoaded(_applyLimit(_cache!, event.limit)));
      return;
    }

    emit(const EntrenamientosLoading());
    try {
      final entrenamientos = await _service.getEntrenamientosRecientes(
        event.asesoradoId,
        limit: event.limit,
      );
      _cache = entrenamientos;
      emit(EntrenamientosLoaded(entrenamientos));
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[EntrenamientosBloc] Error: $e');
        debugPrint(stackTrace.toString());
      }
      emit(const EntrenamientosError('Error cargando entrenamientos.'));
    }
  }

  Future<void> _onLoadMoreEntrenamientos(
    LoadMoreEntrenamientos event,
    Emitter<EntrenamientosState> emit,
  ) async {
    if (state is! EntrenamientosLoaded) return;
    final currentState = state as EntrenamientosLoaded;

    if (currentState.currentPage >= currentState.totalPages) return;

    try {
      emit(currentState.copyWith(isLoading: true, hasMore: true));

      final nextPage = currentState.currentPage + 1;
      final moreEntrenamientos = await _service.getEntrenamientosRecientes(
        _currentAsesoradoId,
        limit: 8,
      );

      final updatedList = [
        ...currentState.entrenamientos,
        ...moreEntrenamientos,
      ];
      final hasMore = nextPage < currentState.totalPages;

      emit(
        currentState.copyWith(
          entrenamientos: updatedList,
          currentPage: nextPage,
          hasMore: hasMore,
          isLoading: false,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[EntrenamientosBloc] Load more error: $e');
      }
      emit(currentState.copyWith(isLoading: false, hasMore: true));
    }
  }

  List<Asignacion> _applyLimit(List<Asignacion> source, int limit) {
    if (limit <= 0 || source.length <= limit) {
      return List<Asignacion>.from(source);
    }
    return source.take(limit).toList();
  }
}
