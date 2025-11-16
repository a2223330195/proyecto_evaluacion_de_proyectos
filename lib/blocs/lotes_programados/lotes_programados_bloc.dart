// lib/blocs/lotes_programados/lotes_programados_bloc.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:coachhub/services/entrenamiento_service.dart';
import 'lotes_programados_event.dart';
import 'lotes_programados_state.dart';

class LotesProgramadosBloc
    extends Bloc<LotesProgramadosEvent, LotesProgramadosState> {
  final _routineService = EntrenamientoService();

  LotesProgramadosBloc() : super(const LotesProgramadosInitial()) {
    on<LoadLotes>(_onLoadLotes);
    on<DeleteLote>(_onDeleteLote);
    on<RefreshLotes>(_onRefreshLotes);
  }

  Future<void> _onLoadLotes(
    LoadLotes event,
    Emitter<LotesProgramadosState> emit,
  ) async {
    emit(const LotesProgramadosLoading());

    try {
      final lotes = await _routineService.getLotesPorAsesorado(
        event.asesoradoId,
      );
      emit(LotesProgramadosLoaded(lotes));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LotesProgramadosBloc] Error cargando lotes: $e');
      }
      emit(LotesProgramadosError('Error cargando lotes: $e'));
    }
  }

  /// Manejador de refresh: recarga los lotes sin mostrar loading
  /// Útil para cuando se programa una nueva rutina
  Future<void> _onRefreshLotes(
    RefreshLotes event,
    Emitter<LotesProgramadosState> emit,
  ) async {
    try {
      final lotes = await _routineService.getLotesPorAsesorado(
        event.asesoradoId,
      );
      emit(LotesProgramadosLoaded(lotes));
      if (kDebugMode) {
        debugPrint(
          '[LotesProgramadosBloc] Lotes refrescados para asesorado ${event.asesoradoId}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LotesProgramadosBloc] Error refrescando lotes: $e');
      }
      emit(LotesProgramadosError('Error refrescando lotes: $e'));
    }
  }

  Future<void> _onDeleteLote(
    DeleteLote event,
    Emitter<LotesProgramadosState> emit,
  ) async {
    try {
      final success = await _routineService.deleteLoteCompleto(event.batchId);

      if (success) {
        // Refrescar la lista de lotes después de eliminar
        if (kDebugMode) {
          debugPrint(
            '[LotesProgramadosBloc] Lote ${event.batchId} eliminado correctamente',
          );
        }
        add(LoadLotes(event.asesoradoId));
      } else {
        if (kDebugMode) {
          debugPrint(
            '[LotesProgramadosBloc] Fallo al eliminar lote ${event.batchId}',
          );
        }
        emit(const LotesProgramadosError('No se pudo eliminar el lote'));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LotesProgramadosBloc] Error eliminando lote: $e');
      }
      emit(LotesProgramadosError('Error eliminando lote: $e'));
    }
  }
}
