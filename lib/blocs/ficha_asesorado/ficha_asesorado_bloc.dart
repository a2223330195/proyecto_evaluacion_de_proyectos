import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:coachhub/models/asesorado_model.dart';
import 'package:coachhub/services/asesorados_service.dart';
import 'ficha_asesorado_event.dart';
import 'ficha_asesorado_state.dart';

class FichaAsesoradoBloc
    extends Bloc<FichaAsesoradoEvent, FichaAsesoradoState> {
  final AsesoradosService _asesoradosService;
  Asesorado? _cache;

  FichaAsesoradoBloc({AsesoradosService? asesoradosService})
    : _asesoradosService = asesoradosService ?? AsesoradosService(),
      super(const FichaAsesoradoInitial()) {
    on<LoadFichaAsesorado>(_onLoadFichaAsesorado);
  }

  Future<void> _onLoadFichaAsesorado(
    LoadFichaAsesorado event,
    Emitter<FichaAsesoradoState> emit,
  ) async {
    if (_cache != null && !event.forceRefresh) {
      emit(FichaAsesoradoLoaded(_cache!));
    } else {
      emit(const FichaAsesoradoLoading());
    }

    try {
      final asesorado = await _asesoradosService.getAsesoradoDetails(
        event.asesoradoId,
      );

      if (asesorado == null) {
        const message = 'No se encontró información del asesorado.';
        emit(const FichaAsesoradoError(message));
        return;
      }

      _cache = asesorado;
      emit(FichaAsesoradoLoaded(asesorado));
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[FichaAsesoradoBloc] Error: $e');
        debugPrint(stackTrace.toString());
      }
      emit(const FichaAsesoradoError('Error cargando la ficha del asesorado.'));
    }
  }
}
