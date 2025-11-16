// lib/blocs/metricas/metricas_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../models/medicion_model.dart';
import '../../services/mediciones_service.dart';
import 'metricas_event.dart';
import 'metricas_state.dart';

class MetricasBloc extends Bloc<MetricasEvent, MetricasState> {
  final MedicionesService _medicionesService = MedicionesService();
  static const int _allDataPageSize = MedicionesService.defaultPageSize;
  int _lastRangeLimit = 5;
  int _currentAsesoradoId = 0;

  MetricasBloc() : super(const MetricasInitial()) {
    on<LoadMedicionesDetalle>(_onLoadMedicionesDetalle);
    on<CrearMedicion>(_onCrearMedicion);
    on<ActualizarMedicion>(_onActualizarMedicion);
    on<EliminarMedicion>(_onEliminarMedicion);
    on<LoadMoreMediciones>(_onLoadMoreMediciones);
  }

  /// Método auxiliar para cargar y emitir mediciones con feedback opcional
  Future<void> _cargarYEmitirMediciones(
    Emitter<MetricasState> emit, {
    required int asesoradoId,
    required int rangeLimit,
    String? feedbackMessage,
    bool emitLoading = true,
  }) async {
    if (emitLoading) {
      emit(MetricasLoading());
    }

    try {
      final totalMediciones = await _medicionesService.countMediciones(
        asesoradoId,
      );

      final bool isFullHistory = rangeLimit <= 0;
      final int effectivePageSize =
          isFullHistory ? _allDataPageSize : rangeLimit;

      List<Medicion> mediciones;
      int totalPages;
      bool hasMore;

      if (isFullHistory) {
        mediciones = await _medicionesService.getMedicionesByAsesoradoPaginated(
          asesoradoId,
          limit: effectivePageSize,
          offset: 0,
        );
      } else {
        mediciones = await _medicionesService.getLatestMediciones(
          asesoradoId,
          limit: rangeLimit,
        );
      }

      totalPages =
          totalMediciones == 0
              ? 1
              : (totalMediciones / effectivePageSize).ceil();
      hasMore = isFullHistory && totalPages > 1;

      final ultimaMedicion = mediciones.isNotEmpty ? mediciones.last : null;
      final medicionesParaLista = mediciones.reversed.toList();

      emit(
        MedicionesDetallesCargados(
          medicionesParaGrafico: mediciones,
          medicionesParaLista: medicionesParaLista,
          ultimaMedicion: ultimaMedicion,
          rangeLimit: rangeLimit,
          feedbackMessage: feedbackMessage,
          currentPage: 1,
          totalPages: totalPages,
          hasMore: hasMore,
          isLoading: false,
        ),
      );

      if (kDebugMode) {
        debugPrint(
          '[MetricasBloc] Cargadas ${mediciones.length} mediciones (limit=$rangeLimit)',
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[MetricasBloc] Error cargando mediciones: $e');
        debugPrint(stackTrace.toString());
      }
      emit(MetricasError('Error cargando mediciones del asesorado.'));
    }
  }

  /// Cargar historial de mediciones para una ficha de asesorado
  Future<void> _onLoadMedicionesDetalle(
    LoadMedicionesDetalle event,
    Emitter<MetricasState> emit,
  ) async {
    // Guardar contexto para los eventos CRUD posteriores
    _lastRangeLimit = event.rangeLimit;
    _currentAsesoradoId = event.asesoradoId;

    await _cargarYEmitirMediciones(
      emit,
      asesoradoId: event.asesoradoId,
      rangeLimit: event.rangeLimit,
      feedbackMessage: null,
      emitLoading: true,
    );
  }

  /// Crear una nueva medición
  Future<void> _onCrearMedicion(
    CrearMedicion event,
    Emitter<MetricasState> emit,
  ) async {
    try {
      await _medicionesService.createMedicion(
        asesoradoId: event.asesoradoId,
        fechaMedicion: event.fechaMedicion,
        peso: event.peso,
        porcentajeGrasa: event.porcentajeGrasa,
        imc: event.imc,
        masaMuscular: event.masaMuscular,
        aguaCorporal: event.aguaCorporal,
        pechoCm: event.pechoCm,
        cinturaCm: event.cinturaCm,
        caderaCm: event.caderaCm,
        brazoIzqCm: event.brazoIzqCm,
        brazoDerCm: event.brazoDerCm,
        piernaIzqCm: event.piernaIzqCm,
        piernaDerCm: event.piernaDerCm,
        pantorrillaIzqCm: event.pantorrillaIzqCm,
        pantorrillaDerCm: event.pantorrillaDerCm,
        frecuenciaCardiaca: event.frecuenciaCardiaca,
        recordResistencia: event.recordResistencia,
      );

      if (kDebugMode) {
        debugPrint('[MetricasBloc] Medición creada exitosamente');
      }

      // Recargar con feedback
      await _cargarYEmitirMediciones(
        emit,
        asesoradoId: event.asesoradoId,
        rangeLimit: _lastRangeLimit,
        feedbackMessage: 'Medición creada con éxito',
        emitLoading: false,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[MetricasBloc] Error creando medición: $e');
        debugPrint(stackTrace.toString());
      }
      emit(MetricasError('Error al crear la medición: $e'));
    }
  }

  /// Actualizar una medición existente
  Future<void> _onActualizarMedicion(
    ActualizarMedicion event,
    Emitter<MetricasState> emit,
  ) async {
    try {
      await _medicionesService.updateMedicion(
        id: event.medicionId,
        fechaMedicion: event.fechaMedicion,
        peso: event.peso,
        porcentajeGrasa: event.porcentajeGrasa,
        imc: event.imc,
        masaMuscular: event.masaMuscular,
        aguaCorporal: event.aguaCorporal,
        pechoCm: event.pechoCm,
        cinturaCm: event.cinturaCm,
        caderaCm: event.caderaCm,
        brazoIzqCm: event.brazoIzqCm,
        brazoDerCm: event.brazoDerCm,
        piernaIzqCm: event.piernaIzqCm,
        piernaDerCm: event.piernaDerCm,
        pantorrillaIzqCm: event.pantorrillaIzqCm,
        pantorrillaDerCm: event.pantorrillaDerCm,
        frecuenciaCardiaca: event.frecuenciaCardiaca,
        recordResistencia: event.recordResistencia,
      );

      if (kDebugMode) {
        debugPrint('[MetricasBloc] Medición actualizada exitosamente');
      }

      // Recargar con feedback
      await _cargarYEmitirMediciones(
        emit,
        asesoradoId: event.asesoradoId,
        rangeLimit: _lastRangeLimit,
        feedbackMessage: 'Medición actualizada con éxito',
        emitLoading: false,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[MetricasBloc] Error actualizando medición: $e');
        debugPrint(stackTrace.toString());
      }
      emit(MetricasError('Error al actualizar la medición: $e'));
    }
  }

  /// Eliminar una medición
  Future<void> _onEliminarMedicion(
    EliminarMedicion event,
    Emitter<MetricasState> emit,
  ) async {
    try {
      await _medicionesService.deleteMedicion(event.medicionId);

      if (kDebugMode) {
        debugPrint('[MetricasBloc] Medición eliminada exitosamente');
      }

      // Recargar con feedback
      await _cargarYEmitirMediciones(
        emit,
        asesoradoId: event.asesoradoId,
        rangeLimit: _lastRangeLimit,
        feedbackMessage: 'Medición eliminada con éxito',
        emitLoading: false,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[MetricasBloc] Error eliminando medición: $e');
        debugPrint(stackTrace.toString());
      }
      emit(MetricasError('Error al eliminar la medición: $e'));
    }
  }

  /// Cargar más mediciones (infinite scroll)
  Future<void> _onLoadMoreMediciones(
    LoadMoreMediciones event,
    Emitter<MetricasState> emit,
  ) async {
    if (state is! MedicionesDetallesCargados) return;
    if (_lastRangeLimit > 0) {
      return;
    }
    final currentState = state as MedicionesDetallesCargados;

    if (!currentState.hasMore || currentState.isLoading) {
      return;
    }

    try {
      emit(currentState.copyWith(isLoading: true));

      final nextPage = currentState.currentPage + 1;
      final offset = (nextPage - 1) * _allDataPageSize;

      final moreMediciones = await _medicionesService
          .getMedicionesByAsesoradoPaginated(
            _currentAsesoradoId,
            limit: _allDataPageSize,
            offset: offset,
          );

      if (moreMediciones.isEmpty) {
        emit(currentState.copyWith(isLoading: false, hasMore: false));
        return;
      }

      final merged = <int, Medicion>{};
      for (final med in currentState.medicionesParaGrafico) {
        merged[med.id] = med;
      }
      for (final med in moreMediciones) {
        merged[med.id] = med;
      }

      final updatedList =
          merged.values.toList()
            ..sort((a, b) => a.fechaMedicion.compareTo(b.fechaMedicion));
      final updatedListaUI = updatedList.reversed.toList();
      final hasMore = nextPage < currentState.totalPages;

      emit(
        currentState.copyWith(
          medicionesParaGrafico: updatedList,
          medicionesParaLista: updatedListaUI,
          currentPage: nextPage,
          hasMore: hasMore,
          isLoading: false,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MetricasBloc] Load more error: $e');
      }
      emit(currentState.copyWith(isLoading: false));
    }
  }
}
