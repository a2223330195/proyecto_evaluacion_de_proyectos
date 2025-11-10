// lib/blocs/bitacora/bitacora_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../models/nota_model.dart';
import '../../services/bitacora_service.dart';
import 'bitacora_event.dart';
import 'bitacora_state.dart';

class BitacoraBloc extends Bloc<BitacoraEvent, BitacoraState> {
  final BitacoraService _service = BitacoraService();

  int _currentAsesoradoId = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  static const int _pageSize = 10;

  BitacoraBloc() : super(const BitacoraInitial()) {
    on<CargarNotasPrioritarias>(_onCargarNotasPrioritarias);
    on<CargarNotasPrioritariasDashboard>(_onCargarNotasPrioritariasDashboard);
    on<CargarTodasLasNotas>(_onCargarTodasLasNotas);
    on<CrearNota>(_onCrearNota);
    on<ActualizarNota>(_onActualizarNota);
    on<EliminarNota>(_onEliminarNota);
    on<TogglePrioritaria>(_onTogglePrioritaria);
    on<BuscarNotas>(_onBuscarNotas);
    on<SiguientePaginaBitacora>(_onSiguientePagina);
    on<PaginaAnteriorBitacora>(_onPaginaAnterior);
    on<RefrescarNotas>(_onRefrescar);
  }

  Future<void> _onCargarNotasPrioritarias(
    CargarNotasPrioritarias event,
    Emitter<BitacoraState> emit,
  ) async {
    emit(const BitacoraLoading());
    try {
      _currentAsesoradoId = event.asesoradoId;
      _currentPage = 1;
      _totalPages = 1;

      final notas = await _service.obtenerNotasPrioritarias(
        _currentAsesoradoId,
      );

      if (kDebugMode) {
        debugPrint(
          '[BitacoraBloc] Cargadas ${notas.length} notas prioritarias',
        );
      }

      emit(NotasPrioritariasLoaded(notas));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BitacoraBloc] Error cargando notas prioritarias: $e');
      }
      emit(BitacoraError('Error cargando notas prioritarias: $e'));
    }
  }

  /// Cargar notas prioritarias de TODOS los asesorados (para Dashboard)
  Future<void> _onCargarNotasPrioritariasDashboard(
    CargarNotasPrioritariasDashboard event,
    Emitter<BitacoraState> emit,
  ) async {
    emit(const BitacoraLoading());
    try {
      final notas = await _service.obtenerNotasPrioritariasPorCoach(
        event.coachId,
      );

      if (kDebugMode) {
        debugPrint(
          '[BitacoraBloc] Cargadas ${notas.length} notas prioritarias del dashboard',
        );
      }

      emit(NotasPrioritariasDashboardLoaded(notas));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BitacoraBloc] Error cargando notas del dashboard: $e');
      }
      emit(BitacoraError('Error cargando notas del dashboard: $e'));
    }
  }

  Future<void> _cargarYEmitirNotas(
    Emitter<BitacoraState> emit, {
    bool setLoading = true,
    String? feedbackMessage,
  }) async {
    if (_currentAsesoradoId == 0) {
      emit(const TodasLasNotasLoaded(notas: [], currentPage: 1, totalPages: 1));
      return;
    }

    if (setLoading) {
      emit(const BitacoraLoading());
    }

    try {
      final totalCount = await _service.contarNotas(_currentAsesoradoId);
      _totalPages = totalCount == 0 ? 1 : (totalCount / _pageSize).ceil();

      if (_currentPage > _totalPages) {
        _currentPage = _totalPages;
      } else if (_currentPage < 1) {
        _currentPage = 1;
      }

      final notas = await _service.obtenerNotasPaginadas(
        asesoradoId: _currentAsesoradoId,
        pageNumber: _currentPage,
        pageSize: _pageSize,
      );

      if (kDebugMode) {
        debugPrint(
          '[BitacoraBloc] Cargada página $_currentPage/$_totalPages '
          '(${notas.length} notas)',
        );
      }

      emit(
        TodasLasNotasLoaded(
          notas: notas,
          currentPage: _currentPage,
          totalPages: _totalPages,
          feedbackMessage: feedbackMessage,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BitacoraBloc] Error cargando notas: $e');
      }
      emit(BitacoraError('Error cargando bitácora: $e'));
    }
  }

  /// Cargar todas las notas (bitácora completa con paginación)
  Future<void> _onCargarTodasLasNotas(
    CargarTodasLasNotas event,
    Emitter<BitacoraState> emit,
  ) async {
    _currentAsesoradoId = event.asesoradoId;
    _currentPage = event.pageNumber;

    await _cargarYEmitirNotas(emit, setLoading: true);
  }

  /// Crear nueva nota
  Future<void> _onCrearNota(
    CrearNota event,
    Emitter<BitacoraState> emit,
  ) async {
    try {
      _currentAsesoradoId = event.asesoradoId;
      final nota = Nota(
        id: 0, // Será asignado por la BD
        asesoradoId: event.asesoradoId,
        contenido: event.contenido,
        prioritaria: event.prioritaria,
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
      );

      await _service.crearNota(nota);

      if (kDebugMode) {
        debugPrint(
          '[BitacoraBloc] Nota creada para asesorado ${event.asesoradoId}',
        );
      }

      _currentPage = 1;
      await _cargarYEmitirNotas(
        emit,
        setLoading: false,
        feedbackMessage: 'Nota creada correctamente',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BitacoraBloc] Error creando nota: $e');
      }
      emit(BitacoraError('Error creando nota: $e'));
    }
  }

  /// Actualizar nota
  Future<void> _onActualizarNota(
    ActualizarNota event,
    Emitter<BitacoraState> emit,
  ) async {
    try {
      final notaActualizada = event.nota.copyWith(
        fechaActualizacion: DateTime.now(),
      );

      await _service.actualizarNota(notaActualizada);

      if (kDebugMode) {
        debugPrint('[BitacoraBloc] Nota ${event.nota.id} actualizada');
      }

      await _cargarYEmitirNotas(
        emit,
        setLoading: false,
        feedbackMessage: 'Nota actualizada correctamente',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BitacoraBloc] Error actualizando nota: $e');
      }
      emit(BitacoraError('Error actualizando nota: $e'));
    }
  }

  /// Eliminar nota
  Future<void> _onEliminarNota(
    EliminarNota event,
    Emitter<BitacoraState> emit,
  ) async {
    try {
      await _service.eliminarNota(event.notaId);

      if (kDebugMode) {
        debugPrint('[BitacoraBloc] Nota ${event.notaId} eliminada');
      }

      await _cargarYEmitirNotas(
        emit,
        setLoading: false,
        feedbackMessage: 'Nota eliminada correctamente',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BitacoraBloc] Error eliminando nota: $e');
      }
      emit(BitacoraError('Error eliminando nota: $e'));
    }
  }

  /// Toggle prioritaria
  Future<void> _onTogglePrioritaria(
    TogglePrioritaria event,
    Emitter<BitacoraState> emit,
  ) async {
    try {
      await _service.togglePrioritaria(event.notaId, event.prioritaria);

      if (kDebugMode) {
        debugPrint(
          '[BitacoraBloc] Nota ${event.notaId} prioridad toggled: ${event.prioritaria}',
        );
      }

      await _cargarYEmitirNotas(
        emit,
        setLoading: false,
        feedbackMessage:
            'Nota marcada como ${event.prioritaria ? 'prioritaria' : 'normal'}',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BitacoraBloc] Error toggling prioritaria: $e');
      }
      emit(BitacoraError('Error actualizando prioridad: $e'));
    }
  }

  /// Buscar notas
  Future<void> _onBuscarNotas(
    BuscarNotas event,
    Emitter<BitacoraState> emit,
  ) async {
    try {
      emit(const BitacoraLoading());
      final notas = await _service.buscarNotas(event.asesoradoId, event.query);

      if (kDebugMode) {
        debugPrint('[BitacoraBloc] Búsqueda encontró ${notas.length} notas');
      }

      emit(ResultadosBusqueda(notas));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BitacoraBloc] Error buscando notas: $e');
      }
      emit(BitacoraError('Error en búsqueda: $e'));
    }
  }

  /// Ir a siguiente página
  Future<void> _onSiguientePagina(
    SiguientePaginaBitacora event,
    Emitter<BitacoraState> emit,
  ) async {
    if (state is! TodasLasNotasLoaded) return;

    final currentState = state as TodasLasNotasLoaded;

    if (currentState.currentPage < currentState.totalPages) {
      _currentPage = currentState.currentPage + 1;
      await _cargarYEmitirNotas(emit, setLoading: true);
    }
  }

  /// Ir a página anterior
  Future<void> _onPaginaAnterior(
    PaginaAnteriorBitacora event,
    Emitter<BitacoraState> emit,
  ) async {
    if (state is! TodasLasNotasLoaded) return;

    final currentState = state as TodasLasNotasLoaded;

    if (currentState.currentPage > 1) {
      _currentPage = currentState.currentPage - 1;
      await _cargarYEmitirNotas(emit, setLoading: true);
    }
  }

  /// Refrescar
  Future<void> _onRefrescar(
    RefrescarNotas event,
    Emitter<BitacoraState> emit,
  ) async {
    await _cargarYEmitirNotas(emit, setLoading: true);
  }
}
