import 'package:coachhub/models/asesorado_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../services/asesorados_service.dart';
import 'asesorados_event.dart';
import 'asesorados_state.dart';

/// BLoC para manejar estado y lógica de asesorados
class AsesoradosBloc extends Bloc<AsesoradosEvent, AsesoradosState> {
  final AsesoradosService _service = AsesoradosService();

  // Estado interno
  int _currentPage = 1;
  int _totalPages = 1;
  int? _coachId;
  String? _searchQuery;
  AsesoradoStatus? _statusFilter;

  AsesoradosBloc() : super(const AsesoradosInitial()) {
    on<LoadAsesorados>(_onLoadAsesorados);
    on<NextPage>(_onNextPage);
    on<PreviousPage>(_onPreviousPage);
    on<DeleteAsesorado>(_onDeleteAsesorado);
    on<RefreshAsesorados>(_onRefreshAsesorados);
    on<LoadMoreAsesorados>(_onLoadMoreAsesorados); // 🛡️ MÓDULO 5
  }

  /// Manejador: Cargar asesorados paginados
  Future<void> _onLoadAsesorados(
    LoadAsesorados event,
    Emitter<AsesoradosState> emit,
  ) async {
    emit(const AsesoradosLoading());
    try {
      _currentPage = event.pageNumber;
      _coachId = event.coachId;
      _searchQuery = event.searchQuery;
      _statusFilter = event.statusFilter;

      // Cargar asesorados paginados
      final asesorados = await _service.getPaginatedAsesorados(
        pageNumber: _currentPage,
        coachId: _coachId,
        searchQuery: _searchQuery,
        statusFilter: _statusFilter,
      );

      // Calcular total de páginas
      final totalCount = await _service.getAsesoradosCount(coachId: _coachId);
      _totalPages = (totalCount / 10).ceil(); // 10 items por página

      if (kDebugMode) {
        debugPrint(
          '[AsesoradosBloc] Cargada página $_currentPage/'
          '$_totalPages (${asesorados.length} items) para coach $_coachId',
        );
      }

      // Calcular si hay más páginas
      final hasMore = _currentPage < _totalPages;

      emit(
        AsesoradosLoaded(
          asesorados: asesorados,
          currentPage: _currentPage,
          totalPages: _totalPages,
          searchQuery: _searchQuery,
          isLoading: false,
          hasMore: hasMore,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AsesoradosBloc] Error cargando asesorados: $e');
      }
      emit(AsesoradosError('Error cargando asesorados: $e'));
    }
  }

  /// Manejador: Ir a siguiente página
  Future<void> _onNextPage(
    NextPage event,
    Emitter<AsesoradosState> emit,
  ) async {
    if (state is! AsesoradosLoaded) return;

    final currentState = state as AsesoradosLoaded;

    if (currentState.currentPage < currentState.totalPages) {
      add(
        LoadAsesorados(
          currentState.currentPage + 1,
          _coachId,
          currentState.searchQuery,
          _statusFilter,
        ),
      );
    }
  }

  /// Manejador: Ir a página anterior
  Future<void> _onPreviousPage(
    PreviousPage event,
    Emitter<AsesoradosState> emit,
  ) async {
    if (state is! AsesoradosLoaded) return;

    final currentState = state as AsesoradosLoaded;

    if (currentState.currentPage > 1) {
      add(
        LoadAsesorados(
          currentState.currentPage - 1,
          _coachId,
          currentState.searchQuery,
          _statusFilter,
        ),
      );
    }
  }

  /// Manejador: Eliminar asesorado
  Future<void> _onDeleteAsesorado(
    DeleteAsesorado event,
    Emitter<AsesoradosState> emit,
  ) async {
    if (state is! AsesoradosLoaded) return;

    try {
      await _service.deleteAsesorado(event.asesoradoId);

      if (kDebugMode) {
        debugPrint('[AsesoradosBloc] Asesorado ${event.asesoradoId} eliminado');
      }

      // Recargar página actual
      add(LoadAsesorados(_currentPage, _coachId, _searchQuery, _statusFilter));

      emit(AsesoradoDeleted('Asesorado eliminado correctamente'));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AsesoradosBloc] Error eliminando asesorado: $e');
      }
      emit(AsesoradosError('Error eliminando asesorado: $e'));
    }
  }

  /// Manejador: Refrescar lista
  Future<void> _onRefreshAsesorados(
    RefreshAsesorados event,
    Emitter<AsesoradosState> emit,
  ) async {
    if (state is! AsesoradosLoaded) return;

    final currentState = state as AsesoradosLoaded;

    add(
      LoadAsesorados(
        currentState.currentPage,
        _coachId,
        currentState.searchQuery,
        _statusFilter,
      ),
    );
  }

  /// 🛡️ MÓDULO 5: Manejador: Cargar más asesorados (infinite scroll)
  /// Append mode: agrega items a la lista existente
  Future<void> _onLoadMoreAsesorados(
    LoadMoreAsesorados event,
    Emitter<AsesoradosState> emit,
  ) async {
    if (state is! AsesoradosLoaded) return;

    final currentState = state as AsesoradosLoaded;

    // Si ya está en la última página, no hacer nada
    if (currentState.currentPage >= currentState.totalPages) {
      if (kDebugMode) {
        debugPrint('[AsesoradosBloc] Ya estamos en la última página');
      }
      return;
    }

    try {
      // Mostrar que se está cargando más (append skeletons)
      emit(currentState.copyWith(isLoading: true, hasMore: true));

      // Cargar siguiente página
      final nextPage = currentState.currentPage + 1;
      final moreAsesorados = await _service.getPaginatedAsesorados(
        pageNumber: nextPage,
        coachId: _coachId,
        searchQuery: _searchQuery,
        statusFilter: _statusFilter,
      );

      if (kDebugMode) {
        debugPrint(
          '[AsesoradosBloc] Cargada página $nextPage (${moreAsesorados.length} items)',
        );
      }

      // Combinar items viejos + nuevos
      final updatedList = [...currentState.asesorados, ...moreAsesorados];

      // Determinar si hay más páginas
      final hasMore = nextPage < currentState.totalPages;

      emit(
        AsesoradosLoaded(
          asesorados: updatedList,
          currentPage: nextPage,
          totalPages: currentState.totalPages,
          searchQuery: _searchQuery,
          isLoading: false,
          hasMore: hasMore, // True si hay más páginas
        ),
      );

      _currentPage = nextPage;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AsesoradosBloc] Error cargando más asesorados: $e');
      }
      // No emitir error, solo restaurar estado anterior
      emit(currentState.copyWith(isLoading: false, hasMore: true));
    }
  }
}
