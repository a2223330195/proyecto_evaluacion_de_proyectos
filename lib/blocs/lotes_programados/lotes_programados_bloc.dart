// lib/blocs/lotes_programados/lotes_programados_bloc.dart

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
      emit(LotesProgramadosError('Error cargando lotes: $e'));
    }
  }

  Future<void> _onDeleteLote(
    DeleteLote event,
    Emitter<LotesProgramadosState> emit,
  ) async {
    try {
      final success = await _routineService.deleteLoteCompleto(event.batchId);

      if (success) {
        // Refrescar la lista de lotes
        add(LoadLotes(event.asesoradoId));
      } else {
        emit(const LotesProgramadosError('No se pudo eliminar el lote'));
      }
    } catch (e) {
      emit(LotesProgramadosError('Error eliminando lote: $e'));
    }
  }
}
