import 'package:coachhub/models/asesorado_pago_pendiente.dart';
import 'package:coachhub/services/pagos_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'pagos_pendientes_event.dart';
import 'pagos_pendientes_state.dart';

/// Bloc dedicado a manejar los pagos pendientes a nivel de coach.
class PagosPendientesBloc
    extends Bloc<PagosPendientesEvent, PagosPendientesState> {
  static const int _pageSize = 20;

  final PagosService _pagosService;

  int _coachId = 0;
  int _currentPage = 1;
  String? _currentFiltro;
  String _currentQuery = '';

  PagosPendientesBloc({PagosService? pagosService})
    : _pagosService = pagosService ?? PagosService(),
      super(const PagosPendientesInitial()) {
    on<CargarPagosPendientes>(_onCargarPagosPendientes);
    on<FiltrarPagosPendientes>(_onFiltrarPagosPendientes);
    on<BuscarEnPagosPendientes>(_onBuscarPagosPendientes);
    on<CambiarPaginaPagosPendientes>(_onCambiarPaginaPagosPendientes);
    on<RegistrarAbonoPendiente>(_onRegistrarAbonoPendiente);
    on<CompletarPagoPendiente>(_onCompletarPagoPendiente);
  }

  Future<void> _onCargarPagosPendientes(
    CargarPagosPendientes event,
    Emitter<PagosPendientesState> emit,
  ) async {
    emit(const PagosPendientesLoading());
    try {
      _coachId = event.coachId;
      _currentPage = event.pageNumber;
      _currentFiltro = _normalizeFiltro(event.filtroEstado);
      _currentQuery = event.searchQuery?.trim() ?? '';

      final asesoradosBase = await _fetchPendientes(
        coachId: event.coachId,
        page: event.pageNumber,
        filtro: _currentFiltro,
      );

      final asesoradosConEstado = await _actualizarSaldoConEstado(
        asesoradosBase,
      );

      final filtered = _aplicarFiltros(
        asesoradosConEstado,
        filtro: _currentFiltro,
        query: _currentQuery,
      );

      final totalMonto = filtered.fold<double>(
        0,
        (sum, a) => sum + a.montoPendiente,
      );

      final totalCount = await _obtenerTotalCount(
        coachId: event.coachId,
        filtro: _currentFiltro,
        baseCount: asesoradosBase.length,
      );

      final totalPages = totalCount == 0 ? 1 : (totalCount / _pageSize).ceil();

      emit(
        PagosPendientesLoaded(
          asesoradosConPago: filtered,
          allAsesorados: asesoradosConEstado,
          currentPage: event.pageNumber,
          totalPages: totalPages,
          totalCount: totalCount,
          filtroEstado: _currentFiltro,
          searchQuery: _currentQuery.isEmpty ? null : _currentQuery,
          totalMontoPendiente: totalMonto,
        ),
      );

      if (kDebugMode) {
        debugPrint(
          '[PagosPendientesBloc] Cargadas ${filtered.length} filas (filtro: ${_currentFiltro ?? 'todos'}, busca: ${_currentQuery.isEmpty ? '-' : _currentQuery}).',
        );
      }
    } catch (e) {
      emit(PagosPendientesError('Error cargando pagos pendientes: $e'));
    }
  }

  Future<void> _onRegistrarAbonoPendiente(
    RegistrarAbonoPendiente event,
    Emitter<PagosPendientesState> emit,
  ) async {
    try {
      _coachId = event.coachId;

      final costoPlan = await _pagosService.obtenerCostoPlan(event.asesoradoId);
      if (costoPlan <= 0) {
        emit(
          const PagosPendientesError(
            'El asesorado no tiene un plan asignado para registrar abonos.',
          ),
        );
        return;
      }

      await _pagosService.registrarAbono(
        asesoradoId: event.asesoradoId,
        monto: event.monto,
        nota: event.nota,
      );

      _pagosService.invalidarCacheCoach(event.coachId);

      add(
        CargarPagosPendientes(
          event.coachId,
          pageNumber: _currentPage,
          filtroEstado: _currentFiltro,
          searchQuery: _currentQuery,
        ),
      );
    } catch (e) {
      emit(PagosPendientesError('Error registrando abono: $e'));
    }
  }

  Future<void> _onCompletarPagoPendiente(
    CompletarPagoPendiente event,
    Emitter<PagosPendientesState> emit,
  ) async {
    try {
      _coachId = event.coachId;

      final tienePlan = await _pagosService.tieneActivoPlan(event.asesoradoId);
      if (!tienePlan) {
        emit(
          const PagosPendientesError(
            'El asesorado no tiene un plan asignado para completar el pago.',
          ),
        );
        return;
      }

      await _pagosService.completarPago(
        asesoradoId: event.asesoradoId,
        monto: event.monto,
        nota: event.nota,
      );

      _pagosService.invalidarCacheCoach(event.coachId);

      add(
        CargarPagosPendientes(
          event.coachId,
          pageNumber: _currentPage,
          filtroEstado: _currentFiltro,
          searchQuery: _currentQuery,
        ),
      );
    } catch (e) {
      emit(PagosPendientesError('Error completando pago: $e'));
    }
  }

  Future<void> _onFiltrarPagosPendientes(
    FiltrarPagosPendientes event,
    Emitter<PagosPendientesState> emit,
  ) async {
    _currentFiltro = _normalizeFiltro(event.estado);

    if (state is! PagosPendientesLoaded) {
      add(
        CargarPagosPendientes(
          _coachId,
          pageNumber: _currentPage,
          filtroEstado: _currentFiltro,
          searchQuery: _currentQuery,
        ),
      );
      return;
    }

    final currentState = state as PagosPendientesLoaded;
    final filtered = _aplicarFiltros(
      currentState.allAsesorados,
      filtro: _currentFiltro,
      query: _currentQuery,
    );

    final totalMonto = filtered.fold<double>(
      0,
      (sum, a) => sum + a.montoPendiente,
    );

    emit(
      currentState.copyWith(
        asesoradosConPago: filtered,
        totalCount: filtered.length,
        filtroEstado: _currentFiltro,
        totalMontoPendiente: totalMonto,
      ),
    );
  }

  Future<void> _onBuscarPagosPendientes(
    BuscarEnPagosPendientes event,
    Emitter<PagosPendientesState> emit,
  ) async {
    _currentQuery = event.query.trim();

    if (state is! PagosPendientesLoaded) {
      add(
        CargarPagosPendientes(
          _coachId,
          pageNumber: _currentPage,
          filtroEstado: _currentFiltro,
          searchQuery: _currentQuery,
        ),
      );
      return;
    }

    final currentState = state as PagosPendientesLoaded;
    final filtered = _aplicarFiltros(
      currentState.allAsesorados,
      filtro: _currentFiltro,
      query: _currentQuery,
    );

    final totalMonto = filtered.fold<double>(
      0,
      (sum, a) => sum + a.montoPendiente,
    );

    emit(
      currentState.copyWith(
        asesoradosConPago: filtered,
        searchQuery: _currentQuery.isEmpty ? null : _currentQuery,
        totalCount: filtered.length,
        totalMontoPendiente: totalMonto,
      ),
    );
  }

  Future<void> _onCambiarPaginaPagosPendientes(
    CambiarPaginaPagosPendientes event,
    Emitter<PagosPendientesState> emit,
  ) async {
    _currentPage = event.page;
    add(
      CargarPagosPendientes(
        _coachId,
        pageNumber: _currentPage,
        filtroEstado: _currentFiltro,
        searchQuery: _currentQuery,
      ),
    );
  }

  String? _normalizeFiltro(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    switch (raw.toLowerCase()) {
      case 'pendiente':
      case 'pendientes':
        return 'pendiente';
      case 'atrasado':
      case 'atrasados':
        return 'atrasado';
      case 'proximo':
      case 'proximos':
      case 'próximo':
      case 'próximos':
        return 'proximo';
      default:
        return null;
    }
  }

  Future<List<AsesoradoPagoPendiente>> _fetchPendientes({
    required int coachId,
    required int page,
    String? filtro,
  }) async {
    if (filtro == 'atrasado') {
      return _pagosService.obtenerAsesoradosConPagosAtrasados(coachId);
    }
    if (filtro == 'proximo') {
      return _pagosService.obtenerAsesoradosConPagosProximos(coachId);
    }

    return _pagosService.obtenerAsesoradosConPagosPendientes(
      coachId,
      page: page,
      pageSize: _pageSize,
    );
  }

  Future<int> _obtenerTotalCount({
    required int coachId,
    String? filtro,
    required int baseCount,
  }) async {
    if (filtro == 'atrasado' || filtro == 'proximo') {
      return baseCount;
    }
    return _pagosService.obtenerCountAsesoradosConPagosPendientes(coachId);
  }

  List<AsesoradoPagoPendiente> _aplicarFiltros(
    List<AsesoradoPagoPendiente> base, {
    String? filtro,
    String? query,
  }) {
    Iterable<AsesoradoPagoPendiente> resultado = base;

    final filtroNormalizado = _normalizeFiltro(filtro);
    if (filtroNormalizado != null) {
      resultado = resultado.where(
        (asesorado) => asesorado.estado == filtroNormalizado,
      );
    }

    final queryNormalizada = query?.trim().toLowerCase() ?? '';
    if (queryNormalizada.isNotEmpty) {
      resultado = resultado.where(
        (asesorado) =>
            asesorado.nombre.toLowerCase().contains(queryNormalizada),
      );
    }

    return resultado.toList(growable: false);
  }

  Future<List<AsesoradoPagoPendiente>> _actualizarSaldoConEstado(
    List<AsesoradoPagoPendiente> base,
  ) async {
    return Future.wait(
      base.map((asesorado) async {
        try {
          final estado = await _pagosService.obtenerEstadoPago(
            asesorado.asesoradoId,
          );
          final saldo =
              estado['saldo_pendiente'] as double? ?? asesorado.montoPendiente;
          final fecha =
              estado['fecha_vencimiento'] as DateTime? ??
              asesorado.fechaVencimiento;
          final estadoLabel = _normalizarEstadoPendiente(
            estado['estado'] as String?,
            asesorado.estado,
          );

          return asesorado.copyWith(
            montoPendiente: saldo,
            fechaVencimiento: fecha,
            estado: estadoLabel,
          );
        } catch (_) {
          return asesorado;
        }
      }),
    );
  }

  String _normalizarEstadoPendiente(String? nuevoEstado, String estadoActual) {
    if (nuevoEstado == null) {
      return estadoActual;
    }

    switch (nuevoEstado) {
      case 'deudor':
        return 'atrasado';
      case 'proximo':
        return 'proximo';
      case 'pendiente':
        return 'pendiente';
      default:
        return estadoActual;
    }
  }
}
