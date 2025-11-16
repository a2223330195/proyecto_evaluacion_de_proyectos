import 'package:coachhub/models/pago_membresia_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../services/pagos_service.dart';
import '../../utils/app_error_handler.dart' as error_handler;
import 'pagos_event.dart';
import 'pagos_state.dart';

/// BLoC para manejar estado y lógica de pagos con optimizaciones
class PagosBloc extends Bloc<PagosEvent, PagosState> {
  final PagosService _service = PagosService();

  // Estado interno
  int _currentAsesoradoId = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _searchQuery;

  // 🚀 OPTIMIZACIÓN 1: Event Deduplication - Evitar eventos duplicados en <200ms
  DateTime? _lastLoadPagosTime;
  final Duration _deduplicationWindow = const Duration(milliseconds: 200);
  _LoadPagosSignature? _lastLoadPagosSignature;

  // 🚀 OPTIMIZACIÓN 2: Cache granular por asesorado
  final Map<int, DateTime> _cacheTimestamps = {}; // asesoradoId -> timestamp

  PagosBloc() : super(const PagosInitial()) {
    on<LoadPagos>(_onLoadPagos);
    on<NextPage>(_onNextPage);
    on<PreviousPage>(_onPreviousPage);
    on<DeletePago>(_onDeletePago);
    on<RefreshPagos>(_onRefreshPagos);
    on<CreatePago>(_onCreatePago);
    on<UpdatePago>(_onUpdatePago);
    on<RecordarAbono>(_onRecordarAbono);
    on<CompletarPago>(_onCompletarPago);
    on<ObtenerEstadoPago>(_onObtenerEstadoPago);
    on<LoadPagosDetails>(_onLoadPagosDetails);
    on<LoadMorePagos>(_onLoadMorePagos); // 🛡️ MÓDULO 5 FASE 5.6
    on<FiltrarPagosPorPeriodo>(
      _onFiltrarPagosPorPeriodo,
    ); // 🎯 NUEVA: Filtrar por período
    on<PagarPorAdelantado>(
      _onPagarPorAdelantado,
    ); // 🎯 NUEVA: Pago por adelantado
  }

  /// Manejador: Cargar pagos paginados
  /// 🛡️ MÓDULO 4: Con manejo de errores mejorado y fallback a cache
  Future<void> _onLoadPagos(LoadPagos event, Emitter<PagosState> emit) async {
    // 🚀 OPTIMIZACIÓN 1: Event Deduplication
    final now = DateTime.now();
    final signature = _LoadPagosSignature(
      asesoradoId: event.asesoradoId,
      pageNumber: event.pageNumber,
      searchQuery: event.searchQuery,
    );

    if (_lastLoadPagosTime != null &&
        _lastLoadPagosSignature == signature &&
        now.difference(_lastLoadPagosTime!).inMilliseconds <
            _deduplicationWindow.inMilliseconds) {
      _lastLoadPagosTime = now;
      if (kDebugMode) {
        debugPrint(
          '[PagosBloc] Evento LoadPagos deduplicado (demasiado pronto)',
        );
      }
      return; // Ignorar evento duplicado
    }
    _lastLoadPagosTime = now;
    _lastLoadPagosSignature = signature;

    emit(const PagosLoading());
    try {
      _currentAsesoradoId = event.asesoradoId;
      _currentPage = event.pageNumber;
      _searchQuery = event.searchQuery;

      // 🚀 OPTIMIZACIÓN 3: Parallelizar queries (Future.wait)
      final futures = [
        _service.getPagosByAsesoradoPaginated(
          asesoradoId: _currentAsesoradoId,
          pageNumber: _currentPage,
        ),
        _service.getPagosCount(_currentAsesoradoId),
        _service.getPagosTotalAmount(_currentAsesoradoId),
      ];

      final results = await Future.wait(futures);
      final pagos = results[0] as List<PagoMembresia>;
      final totalCount = results[1] as int;
      final totalAmount = results[2] as double;

      _totalPages = totalCount == 0 ? 1 : (totalCount / 10).ceil();

      // 🚀 OPTIMIZACIÓN 2: Actualizar cache timestamp
      _cacheTimestamps[_currentAsesoradoId] = DateTime.now();

      if (kDebugMode) {
        debugPrint(
          '[PagosBloc] Cargada página $_currentPage/'
          '$_totalPages (${pagos.length} items) - Parallelizado ⚡',
        );
      }

      emit(
        PagosLoaded(
          pagos: pagos,
          currentPage: _currentPage,
          totalPages: _totalPages,
          searchQuery: _searchQuery,
          isLoading: false,
          totalAmount: totalAmount,
          fromCache: false,
        ),
      );
    } catch (e, stack) {
      // 🛡️ MÓDULO 4: Manejo de errores mejorado
      final errorType = error_handler.AppErrorHandler.categorizeError(e);
      final userMessage = error_handler.AppErrorHandler.getUserMessage(
        errorType,
      );
      final isRetryable = error_handler.AppErrorHandler.isRetryable(errorType);

      error_handler.AppErrorHandler.logError(
        e,
        stack,
        context: '_onLoadPagos for asesoradoId: $_currentAsesoradoId',
      );

      if (kDebugMode) {
        debugPrint('[PagosBloc] Error cargando pagos: $e (Tipo: $errorType)');
      }

      // Emitir error con flag de retry disponible
      emit(
        PagosError(
          userMessage,
          isNetworkError: errorType == error_handler.ErrorType.networkError,
          canRetry: isRetryable,
        ),
      );
    }
  }

  /// Manejador: Ir a siguiente página
  Future<void> _onNextPage(NextPage event, Emitter<PagosState> emit) async {
    if (state is! PagosLoaded) return;

    final currentState = state as PagosLoaded;

    if (currentState.currentPage < currentState.totalPages) {
      add(
        LoadPagos(
          _currentAsesoradoId,
          currentState.currentPage + 1,
          currentState.searchQuery,
        ),
      );
    }
  }

  /// Manejador: Ir a página anterior
  Future<void> _onPreviousPage(
    PreviousPage event,
    Emitter<PagosState> emit,
  ) async {
    if (state is! PagosLoaded) return;

    final currentState = state as PagosLoaded;

    if (currentState.currentPage > 1) {
      add(
        LoadPagos(
          _currentAsesoradoId,
          currentState.currentPage - 1,
          currentState.searchQuery,
        ),
      );
    }
  }

  /// Manejador: Eliminar pago
  /// 🛡️ MÓDULO 4: Con retry logic y mejor error handling
  Future<void> _onDeletePago(DeletePago event, Emitter<PagosState> emit) async {
    if (state is! PagosLoaded) return;

    try {
      // 🛡️ MÓDULO 4: Usar retry logic automático
      await error_handler.executeWithRetry(
        () => _service.deletePago(event.pagoId),
        operationName: 'deletePago(${event.pagoId})',
      );

      if (kDebugMode) {
        debugPrint('[PagosBloc] Pago ${event.pagoId} eliminado');
      }

      // 🚀 OPTIMIZACIÓN 2: Invalidar cache granular (solo este asesorado)
      _invalidateCache(_currentAsesoradoId);

      // Recargar página actual
      add(LoadPagos(_currentAsesoradoId, _currentPage, _searchQuery));

      emit(PagoDeleted('Pago eliminado correctamente'));
    } catch (e, stack) {
      // 🛡️ MÓDULO 4: Manejo de errores mejorado
      final errorType = error_handler.AppErrorHandler.categorizeError(e);
      final userMessage = error_handler.AppErrorHandler.getUserMessage(
        errorType,
      );
      final isRetryable = error_handler.AppErrorHandler.isRetryable(errorType);

      error_handler.AppErrorHandler.logError(
        e,
        stack,
        context: '_onDeletePago(${event.pagoId})',
      );

      if (kDebugMode) {
        debugPrint('[PagosBloc] Error eliminando pago: $e');
      }

      emit(
        PagosError(
          'Error: $userMessage',
          isNetworkError: errorType == error_handler.ErrorType.networkError,
          canRetry: isRetryable,
        ),
      );
    }
  }

  /// Manejador: Refrescar lista
  Future<void> _onRefreshPagos(
    RefreshPagos event,
    Emitter<PagosState> emit,
  ) async {
    if (state is! PagosLoaded) return;

    final currentState = state as PagosLoaded;

    add(
      LoadPagos(
        _currentAsesoradoId,
        currentState.currentPage,
        currentState.searchQuery,
      ),
    );
  }

  /// Manejador: Crear nuevo pago
  Future<void> _onCreatePago(CreatePago event, Emitter<PagosState> emit) async {
    try {
      final mesActual =
          '${event.fechaPago.year}-${event.fechaPago.month.toString().padLeft(2, '0')}';
      final newPago = PagoMembresia(
        id: 0, // Will be assigned by database
        asesoradoId: event.asesoradoId,
        fechaPago: event.fechaPago,
        monto: event.monto,
        periodo: mesActual,
        tipo: TipoPago.completo,
        nota: event.nota,
      );

      await _service.createPago(newPago);

      if (kDebugMode) {
        debugPrint(
          '[PagosBloc] Pago creado para asesorado ${event.asesoradoId}',
        );
      }

      // Recargar lista desde la primera página
      add(LoadPagos(event.asesoradoId, 1, _searchQuery));

      emit(PagoCreatedOrUpdated('Pago creado correctamente'));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PagosBloc] Error creando pago: $e');
      }
      emit(PagosError('Error creando pago: $e'));
    }
  }

  /// Manejador: Actualizar pago existente
  Future<void> _onUpdatePago(UpdatePago event, Emitter<PagosState> emit) async {
    try {
      final mesActual =
          '${event.fechaPago.year}-${event.fechaPago.month.toString().padLeft(2, '0')}';
      final updatedPago = PagoMembresia(
        id: event.pagoId,
        asesoradoId: _currentAsesoradoId,
        fechaPago: event.fechaPago,
        monto: event.monto,
        periodo: mesActual,
        tipo: TipoPago.completo,
        nota: event.nota,
      );

      await _service.updatePago(updatedPago);

      if (kDebugMode) {
        debugPrint('[PagosBloc] Pago ${event.pagoId} actualizado');
      }

      // Recargar página actual
      add(LoadPagos(_currentAsesoradoId, _currentPage, _searchQuery));

      emit(PagoCreatedOrUpdated('Pago actualizado correctamente'));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PagosBloc] Error actualizando pago: $e');
      }
      emit(PagosError('Error actualizando pago: $e'));
    }
  }

  /// Manejador: Registrar abono parcial (NUEVO - DEPRECADO, usar CompletarPago)
  /// ⚠️ DEPRECADO: Este evento sigue existiendo por compatibilidad, pero usa registrarPago()
  Future<void> _onRecordarAbono(
    RecordarAbono event,
    Emitter<PagosState> emit,
  ) async {
    try {
      // ✅ Usar método unificado registrarPago()
      final resultado = await _service.registrarPago(
        asesoradoId: event.asesoradoId,
        monto: event.monto,
        nota: event.nota,
      );

      if (kDebugMode) {
        debugPrint(
          "[PagosBloc] Abono registrado: ${event.monto}, periodo: ${resultado['periodo']}, saldo pendiente: ${resultado['saldo_pendiente']}",
        );
      }

      final periodoCompletado =
          (resultado['periodo_completado'] as bool?) ?? false;
      final saldoPendiente = (resultado['saldo_pendiente'] as double?) ?? 0.0;

      // 🎯 FIX: En lugar de recargar el estado del siguiente período,
      // emitir manualmente el estado actual con saldo pendiente = \$0.00
      if (periodoCompletado) {
        // ✅ Período completamente pagado
        if (kDebugMode) {
          debugPrint(
            '[PagosBloc] Período ${resultado['periodo']} completado. Mostrando saldo \$0.00',
          );
        }

        emit(
          AbonoRegistrado(
            saldoPendiente: 0.0,
            totalAbonado:
                (resultado['total_abonado'] as double?) ?? event.monto,
            periodo: resultado['periodo'] as String,
          ),
        );
        add(
          LoadPagosDetails(
            event.asesoradoId,
            feedbackMessage: 'Abono registrado y saldo del período cubierto.',
          ),
        );
      } else {
        // ⚠️ Aún hay saldo pendiente
        if (kDebugMode) {
          debugPrint(
            '[PagosBloc] Abono registrado. Saldo pendiente: \$${saldoPendiente.toStringAsFixed(2)}',
          );
        }

        emit(
          AbonoRegistrado(
            saldoPendiente: saldoPendiente,
            totalAbonado:
                (resultado['total_abonado'] as double?) ?? event.monto,
            periodo: resultado['periodo'] as String,
          ),
        );
        add(
          LoadPagosDetails(
            event.asesoradoId,
            feedbackMessage: 'Abono registrado correctamente.',
          ),
        );
      }

      _invalidateCache(event.asesoradoId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PagosBloc] Error registrando abono: $e');
      }
      emit(PagosError('Error registrando abono: $e'));
    }
  }

  /// Manejador: Completar pago (NUEVO - unificado con registrarAbono)
  /// ✅ MEJORA: Usa método unificado registrarPago() que determina tipo POST-inserción
  Future<void> _onCompletarPago(
    CompletarPago event,
    Emitter<PagosState> emit,
  ) async {
    try {
      // ✅ Usar método unificado registrarPago()
      final resultado = await _service.registrarPago(
        asesoradoId: event.asesoradoId,
        monto: event.monto,
        nota: event.nota,
      );

      if (kDebugMode) {
        debugPrint(
          "[PagosBloc] Pago registrado: ${event.monto} para período ${resultado['periodo']}, tipo: ${resultado['tipo_pago']}",
        );
      }

      // 🎯 TAREA 1.3: Verificar y aplicar estado de abono
      // ⚠️ No causa extensión duplicada gracias a cambio en verificarYAplicarEstadoAbono
      await _service.verificarYAplicarEstadoAbono(
        asesoradoId: event.asesoradoId,
        periodo: resultado['periodo'] as String,
      );

      // 🎯 Extraer el flag periodo_completado para determinar si es pago completo o abono
      final periodoCompletado =
          (resultado['periodo_completado'] as bool?) ?? false;
      final saldoPendiente = (resultado['saldo_pendiente'] as double?) ?? 0.0;
      final periodo = resultado['periodo'] as String;
      final totalAbonado =
          (resultado['total_abonado'] as double?) ?? event.monto;

      // 🎯 FIX: NO llamar a add(LoadPagosDetails(...)) para evitar recargar el siguiente período
      // En su lugar, emitir manualmente el estado con saldo $0.00 si período se completó
      if (periodoCompletado) {
        // ✅ Período completamente pagado → mostrar saldo $0.00
        if (kDebugMode) {
          debugPrint(
            '[PagosBloc] Período $periodo completamente pagado. Membresía extendida. Mostrando saldo \$0.00',
          );
        }

        emit(PagoCompletado(periodo: periodo, montoTotal: event.monto));
        add(
          LoadPagosDetails(
            event.asesoradoId,
            feedbackMessage: 'Pago completado y membresía actualizada.',
          ),
        );
      } else {
        // ⚠️ Aún hay saldo pendiente → emitir AbonoRegistrado
        if (kDebugMode) {
          debugPrint(
            '[PagosBloc] Abono registrado, pero período aún no completado. Saldo: \$${saldoPendiente.toStringAsFixed(2)}',
          );
        }

        emit(
          AbonoRegistrado(
            saldoPendiente: saldoPendiente,
            totalAbonado: totalAbonado,
            periodo: periodo,
          ),
        );
        add(
          LoadPagosDetails(
            event.asesoradoId,
            feedbackMessage: 'Pago parcial registrado.',
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PagosBloc] Error completando pago: $e');
      }
      emit(PagosError('Error completando pago: $e'));
    }
  }

  /// Manejador: Obtener estado del pago (NUEVO)
  Future<void> _onObtenerEstadoPago(
    ObtenerEstadoPago event,
    Emitter<PagosState> emit,
  ) async {
    try {
      final estadoData = await _service.obtenerEstadoPago(event.asesoradoId);

      if (kDebugMode) {
        debugPrint(
          '[PagosBloc] Estado pago: ${estadoData['estado']}, saldo: ${estadoData['saldo_pendiente']}',
        );
      }

      emit(
        EstatusPageObtenido(
          estado: estadoData['estado'] as String,
          saldoPendiente: (estadoData['saldo_pendiente'] as double?) ?? 0.0,
          fechaVencimiento: estadoData['fecha_vencimiento'] as DateTime?,
          planNombre: estadoData['plan_nombre'] as String?,
          costoPlan: estadoData['costo_plan'] as double?,
          periodoSugerido: estadoData['periodo_a_pagar'] as String?,
          totalAbonadoPeriodo:
              estadoData['total_abonado_periodo'] as double? ?? 0.0,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PagosBloc] Error obteniendo estado: $e');
      }
      emit(PagosError('Error obteniendo estado de pago: $e'));
    }
  }

  /// Manejador: Cargar detalles completos de pagos (plan + estado + historial)
  Future<void> _onLoadPagosDetails(
    LoadPagosDetails event,
    Emitter<PagosState> emit,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[PagosBloc] Cargando detalles de pagos para asesorado ${event.asesoradoId}',
        );
      }

      // 🚀 OPTIMIZACIÓN 3: Paralelizar queries y evitar duplicados
      // 🎯 Cargar historial completo una sola vez para reutilizarlo en filtros
      final futures = [
        _service.obtenerEstadoPago(event.asesoradoId),
        _service.getPagosCompletos(asesoradoId: event.asesoradoId),
        _service.getPagosTotalAmount(event.asesoradoId),
        _service.obtenerTodosPeriodos(event.asesoradoId),
      ];

      final results = await Future.wait(futures);
      final estadoData = results[0] as Map<String, dynamic>;
      final pagosCompletos = results[1] as List<PagoMembresia>;
      final totalAmount = results[2] as double;
      final periodosDisponibles = results[3] as List<String>;

      // 📊 VALIDACIÓN: Advertencia si el historial es muy grande (riesgo de memoria)
      if (pagosCompletos.length > 500) {
        if (kDebugMode) {
          debugPrint(
            '[PagosBloc] ⚠️ ADVERTENCIA: Historial muy grande (${pagosCompletos.length} registros). Considerar pagination en getPagosCompletos()',
          );
        }
      } else if (kDebugMode) {
        debugPrint(
          '[PagosBloc] Historial cargado: ${pagosCompletos.length} registros en memoria',
        );
      }

      final totalCount = pagosCompletos.length;
      _totalPages =
          totalCount == 0
              ? 1
              : (totalCount / PagosService.defaultPageSize).ceil();

      // 🚀 OPTIMIZACIÓN 2: Actualizar cache timestamp
      _cacheTimestamps[event.asesoradoId] = DateTime.now();

      String estado =
          (estadoData['estado'] as String?)?.toLowerCase() ?? 'desconocido';
      double saldoPendiente = (estadoData['saldo_pendiente'] as double?) ?? 0.0;
      final DateTime? fechaVencimiento =
          estadoData['fecha_vencimiento'] as DateTime?;

      if (saldoPendiente <= 0.0001) {
        saldoPendiente = 0.0;
        if (estado != 'pagado') {
          estado = 'pagado';
        }
      }
      estadoData['estado'] = estado;
      estadoData['saldo_pendiente'] = saldoPendiente;

      final bool puedePagarAnticipado =
          (estadoData['puede_pagar_anticipado'] as bool?) ?? false;
      final bool enVentanaCorte =
          (estadoData['en_ventana_corte'] as bool?) ?? false;
      final String? ultimoPeriodoPagado =
          estadoData['ultimo_periodo_pagado'] as String?;

      // 3. Emitir estado con todo integrado
      emit(
        PagosDetallesCargados(
          estado: estado,
          saldoPendiente: saldoPendiente,
          fechaVencimiento: fechaVencimiento,
          planNombre: estadoData['plan_nombre'] as String?,
          costoPlan: estadoData['costo_plan'] as double?,
          periodoSugerido: estadoData['periodo_a_pagar'] as String?,
          totalAbonadoPeriodo:
              estadoData['total_abonado_periodo'] as double? ?? 0.0,
          pagos: pagosCompletos,
          todosPagos: pagosCompletos, // 🎯 CORREGIDO: usar historial completo
          currentPage: 1,
          totalPages: _totalPages,
          totalAmount: totalAmount,
          feedbackMessage: event.feedbackMessage,
          periodosDisponibles: periodosDisponibles,
          ultimoPeriodoPagado: ultimoPeriodoPagado,
          puedePagarAnticipado: puedePagarAnticipado,
          enVentanaCorte: enVentanaCorte,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PagosBloc] Error cargando detalles de pagos: $e');
      }
      emit(PagosError('Error cargando detalles de pagos: $e'));
    }
  }

  /// Manejador: Cambiar criterio de ordenamiento (por periodo o por fecha)
  /// 🎯 NUEVA FUNCIONALIDAD: Filtrar pagos por período seleccionado
  /// Si periodoSeleccionado es null, muestra todos los pagos
  /// Si periodoSeleccionado tiene valor (ej: '2025-01'), filtra solo ese período
  /// 🎯 CORREGIDO: Usa todosPagos (colección completa) para filtrado sin truncamiento
  Future<void> _onFiltrarPagosPorPeriodo(
    FiltrarPagosPorPeriodo event,
    Emitter<PagosState> emit,
  ) async {
    try {
      if (state is! PagosDetallesCargados) return;
      final currentState = state as PagosDetallesCargados;

      // 🎯 CORREGIDO: Filtrar desde todosPagos (colección completa) no desde pagos (truncada)
      List<PagoMembresia> pagosFiltrados = currentState.todosPagos;

      if (event.periodoSeleccionado != null &&
          event.periodoSeleccionado!.isNotEmpty) {
        pagosFiltrados =
            currentState.todosPagos
                .where((pago) => pago.periodo == event.periodoSeleccionado)
                .toList();

        if (kDebugMode) {
          debugPrint(
            '[PagosBloc] Filtrando pagos por período: ${event.periodoSeleccionado} '
            '(${pagosFiltrados.length} resultados de ${currentState.todosPagos.length} totales)',
          );
        }
      } else {
        if (kDebugMode) {
          debugPrint(
            '[PagosBloc] Mostrando todos los pagos (${currentState.todosPagos.length} totales)',
          );
        }
      }

      // Emitir estado actualizado con período seleccionado
      emit(
        currentState.copyWith(
          pagos: pagosFiltrados, // Campo filtrado para mostrar en UI
          periodoSeleccionado: event.periodoSeleccionado,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PagosBloc] Error filtrando por período: $e');
      }
      emit(PagosError('Error filtrando por período: $e'));
    }
  }

  /// 🚀 MÉTODO HELPER: Invalidar cache granular por asesorado
  void _invalidateCache(int asesoradoId) {
    _cacheTimestamps[asesoradoId] = DateTime.now();
    if (kDebugMode) {
      debugPrint('[PagosBloc] Cache invalidado para asesorado $asesoradoId');
    }
  }

  /// 🛡️ MÓDULO 5 FASE 5.6: Cargar más pagos (infinite scroll)
  /// Append mode: agrega items a la lista existente
  Future<void> _onLoadMorePagos(
    LoadMorePagos event,
    Emitter<PagosState> emit,
  ) async {
    if (state is! PagosLoaded) return;
    final currentState = state as PagosLoaded;

    // Si ya en última página, no hacer nada
    if (currentState.currentPage >= currentState.totalPages) return;

    try {
      // Emitir estado con isLoading=true (mostrar skeletons)
      emit(currentState.copyWith(isLoading: true, hasMore: true));

      // Cargar siguiente página
      final nextPage = currentState.currentPage + 1;
      final morePagos = await _service.getPagosByAsesoradoPaginated(
        asesoradoId: _currentAsesoradoId,
        pageNumber: nextPage,
      );

      // Append a lista existente (no resetear)
      final updatedList = [...currentState.pagos, ...morePagos];
      final hasMore = nextPage < currentState.totalPages;

      if (kDebugMode) {
        debugPrint(
          '[PagosBloc] LoadMore: página $nextPage/${currentState.totalPages} '
          '(+${morePagos.length} pagos) - Total: ${updatedList.length}',
        );
      }

      // Emitir nuevo estado
      emit(
        currentState.copyWith(
          pagos: updatedList,
          currentPage: nextPage,
          hasMore: hasMore,
          isLoading: false,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PagosBloc] Error en LoadMore: $e');
      }
      // Soft fail: mantener estado anterior sin error visual
      emit(currentState.copyWith(isLoading: false, hasMore: true));
    }
  }

  /// 🎯 NUEVA: Manejador para pago por adelantado
  /// Reutiliza la lógica de registrarPago pero con período específico
  Future<void> _onPagarPorAdelantado(
    PagarPorAdelantado event,
    Emitter<PagosState> emit,
  ) async {
    try {
      // ✅ Usar método unificado registrarPago()
      final resultado = await _service.registrarPago(
        asesoradoId: event.asesoradoId,
        monto: event.monto,
        nota: event.nota,
      );

      if (kDebugMode) {
        debugPrint(
          "[PagosBloc] Pago adelantado registrado: ${event.monto} para período ${resultado['periodo']}",
        );
      }

      // ✅ Verificar y aplicar estado de abono
      await _service.verificarYAplicarEstadoAbono(
        asesoradoId: event.asesoradoId,
        periodo: resultado['periodo'] as String,
      );

      final periodoCompletado =
          (resultado['periodo_completado'] as bool?) ?? false;

      if (periodoCompletado) {
        if (kDebugMode) {
          debugPrint(
            '[PagosBloc] Período ${resultado['periodo']} completado por pago adelantado.',
          );
        }

        emit(
          PagoCompletado(
            periodo: resultado['periodo'] as String,
            montoTotal: event.monto,
          ),
        );
        add(
          LoadPagosDetails(
            event.asesoradoId,
            feedbackMessage:
                'Pago adelantado registrado para ${resultado['periodo']}.',
          ),
        );
      } else {
        emit(
          AbonoRegistrado(
            saldoPendiente: (resultado['saldo_pendiente'] as double?) ?? 0.0,
            totalAbonado:
                (resultado['total_abonado'] as double?) ?? event.monto,
            periodo: resultado['periodo'] as String,
          ),
        );
        add(
          LoadPagosDetails(
            event.asesoradoId,
            feedbackMessage: 'Pago adelantado registrado.',
          ),
        );
      }

      _invalidateCache(event.asesoradoId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PagosBloc] Error en pago adelantado: $e');
      }
      emit(PagosError('Error registrando pago adelantado: $e'));
    }
  }
}

class _LoadPagosSignature {
  final int asesoradoId;
  final int pageNumber;
  final String? searchQuery;

  const _LoadPagosSignature({
    required this.asesoradoId,
    required this.pageNumber,
    required this.searchQuery,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _LoadPagosSignature) return false;
    return asesoradoId == other.asesoradoId &&
        pageNumber == other.pageNumber &&
        searchQuery == other.searchQuery;
  }

  @override
  int get hashCode => Object.hash(asesoradoId, pageNumber, searchQuery);
}
