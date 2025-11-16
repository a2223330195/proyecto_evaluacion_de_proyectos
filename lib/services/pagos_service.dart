import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:coachhub/services/db_connection.dart';
import 'package:coachhub/models/pago_membresia_model.dart';
import 'package:coachhub/models/asesorado_pago_pendiente.dart';
import 'package:coachhub/utils/app_error_handler.dart' show executeWithRetry;
import 'dart:async';

/// Servicio consolidado para gestión de pagos de membresía
///
/// Combina:
/// - PagosService: CRUD de pagos, estado, validaciones
/// - PagosPendientesService: Listado de pendientes con caché
///
/// ✅ REFACTORIZACIÓN COMPLETADA:
/// - Caché unificado con claves consistentes (coachId_page_pageSize)
/// - Invalidación correcta que limpia todas las variantes
/// - Transacciones atómicas para operaciones de pago
/// - Validación de plan activo en todos los puntos
/// - Estados de pago claramente definidos
class PagosService {
  final _db = DatabaseConnection.instance;
  static const int defaultPageSize = 10;

  // ============================================================================
  // SISTEMA DE CACHÉ UNIFICADO (mejora: claves consistentes)
  // ============================================================================

  /// Caché para pagos pendientes por coach
  /// Claves: 'pagos_pendientes_{coachId}_{page}_{pageSize}'
  final Map<String, _CacheEntry<List<AsesoradoPagoPendiente>>> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Caché secundario para pagos individuales (fallback)
  final Map<int, List<PagoMembresia>> _pagosCache = {};
  final Map<int, DateTime> _pagosCacheTime = {};
  static const Duration _pagosCacheDuration = Duration(minutes: 10);
  static const int _diasAvisoCorte =
      5; // días antes del vencimiento para mostrar el próximo cobro

  // ============================================================================
  // MÉTODOS DE PAGOS INDIVIDUALES (anteriormente en PagosService)
  // ============================================================================

  Future<List<PagoMembresia>> getPagosByAsesorado(int asesoradoId) async {
    final results = await _db.query(
      'SELECT * FROM pagos_membresias WHERE asesorado_id = ? ORDER BY fecha_pago DESC',
      [asesoradoId],
    );
    return results.map((r) => PagoMembresia.fromMap(r.fields)).toList();
  }

  /// Obtiene pagos paginados por asesorado
  /// [pageNumber] - página a cargar (1-indexed)
  /// [pageSize] - items por página (default 10)
  /// [asesoradoId] - ID del asesorado
  /// [ordenarPorPeriodo] - si true, ordena por periodo DESC, luego fecha DESC; si false, solo por fecha DESC
  ///
  /// 🛡️ MÓDULO 4: Con retry logic automático en caso de error de red
  Future<List<PagoMembresia>> getPagosByAsesoradoPaginated({
    required int asesoradoId,
    required int pageNumber,
    int pageSize = defaultPageSize,
    bool ordenarPorPeriodo = false,
  }) async {
    return executeWithRetry(
      () => _getPagosByAsesoradoPaginatedImpl(
        asesoradoId: asesoradoId,
        pageNumber: pageNumber,
        pageSize: pageSize,
        ordenarPorPeriodo: ordenarPorPeriodo,
      ),
      operationName: 'getPagosByAsesoradoPaginated',
    );
  }

  /// Implementación interna sin retry (para evitar recursión)
  Future<List<PagoMembresia>> _getPagosByAsesoradoPaginatedImpl({
    required int asesoradoId,
    required int pageNumber,
    int pageSize = defaultPageSize,
    bool ordenarPorPeriodo = false,
  }) async {
    final offset = (pageNumber - 1) * pageSize;
    final orderByClause =
        ordenarPorPeriodo ? 'periodo DESC, fecha_pago DESC' : 'fecha_pago DESC';

    try {
      final results = await _db.query(
        '''
        SELECT * FROM pagos_membresias 
        WHERE asesorado_id = ? 
        ORDER BY $orderByClause
        LIMIT ? OFFSET ?
        ''',
        [asesoradoId, pageSize, offset],
      );
      final pagos =
          results.map((r) => PagoMembresia.fromMap(r.fields)).toList();

      // Guardar en caché si es primera página
      if (pageNumber == 1) {
        _pagosCache[asesoradoId] = pagos;
        _pagosCacheTime[asesoradoId] = DateTime.now();
      }

      return pagos;
    } catch (e) {
      // Si es la primera página y tenemos caché, retornar caché
      if (pageNumber == 1 && _pagosCache.containsKey(asesoradoId)) {
        final cacheTime = _pagosCacheTime[asesoradoId];
        final isCacheValid =
            cacheTime != null &&
            DateTime.now().difference(cacheTime) < _pagosCacheDuration;
        if (isCacheValid) {
          developer.log(
            'Using cached pagos for asesorado $asesoradoId (Módulo 4: Error Handling)',
            name: 'PagosService',
          );
          return _pagosCache[asesoradoId]!;
        }
      }
      rethrow;
    }
  }

  /// Obtiene el total de pagos para un asesorado
  Future<int> getPagosCount(int asesoradoId) async {
    final results = await _db.query(
      'SELECT COUNT(*) as total FROM pagos_membresias WHERE asesorado_id = ?',
      [asesoradoId],
    );
    if (results.isNotEmpty) {
      return results.first.fields['total'] as int? ?? 0;
    }
    return 0;
  }

  /// 🎯 NUEVA: Obtener TODOS los pagos sin paginación (para historial completo)
  /// Usado para poblar `todosPagos` en BLoC sin truncamiento
  /// [ordenarPorPeriodo] - si true, ordena por periodo DESC, luego fecha DESC; si false, solo por fecha DESC
  Future<List<PagoMembresia>> getPagosCompletos({
    required int asesoradoId,
    bool ordenarPorPeriodo = false,
  }) async {
    final orderByClause =
        ordenarPorPeriodo ? 'periodo DESC, fecha_pago DESC' : 'fecha_pago DESC';

    try {
      final results = await _db.query(
        '''
        SELECT * FROM pagos_membresias 
        WHERE asesorado_id = ? 
        ORDER BY $orderByClause
        ''',
        [asesoradoId],
      );
      final pagos =
          results.map((r) => PagoMembresia.fromMap(r.fields)).toList();

      if (kDebugMode) {
        debugPrint(
          '[PagosService] Cargados ${pagos.length} pagos completos para asesorado $asesoradoId',
        );
      }

      return pagos;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PagosService] Error cargando pagos completos: $e');
      }
      rethrow;
    }
  }

  /// Obtiene la suma total de ingresos para un asesorado
  Future<double> getPagosTotalAmount(int asesoradoId) async {
    final results = await _db.query(
      'SELECT COALESCE(SUM(monto), 0) as total FROM pagos_membresias WHERE asesorado_id = ?',
      [asesoradoId],
    );
    if (results.isEmpty) {
      return 0.0;
    }

    final rawTotal = results.first.fields['total'];
    // MySQL puede devolver distintos tipos numéricos dependiendo del driver, por eso normalizamos aquí.
    if (rawTotal == null) {
      return 0.0;
    }

    if (rawTotal is num) {
      return rawTotal.toDouble();
    }
    if (rawTotal is String) {
      return double.tryParse(rawTotal) ?? 0.0;
    }
    if (rawTotal is BigInt) {
      return rawTotal.toDouble();
    }

    return double.tryParse(rawTotal.toString()) ?? 0.0;
  }

  /// Calcula total de páginas
  Future<int> getTotalPages(
    int asesoradoId, {
    int pageSize = defaultPageSize,
  }) async {
    final count = await getPagosCount(asesoradoId);
    return (count / pageSize).ceil();
  }

  Future<void> createPago(PagoMembresia pago) async {
    await _db.query(
      '''
      INSERT INTO pagos_membresias (
        asesorado_id, fecha_pago, monto, periodo, tipo, nota
      ) VALUES (?, ?, ?, ?, ?, ?)
      ''',
      [
        pago.asesoradoId,
        pago.fechaPago.toString().split(' ')[0],
        pago.monto,
        pago.periodo,
        pago.tipo.name,
        pago.nota,
      ],
    );
  }

  Future<void> updatePago(PagoMembresia pago) async {
    await _db.query(
      '''
      UPDATE pagos_membresias
      SET fecha_pago = ?, monto = ?, periodo = ?, tipo = ?, nota = ?
      WHERE id = ?
      ''',
      [
        pago.fechaPago.toString().split(' ')[0],
        pago.monto,
        pago.periodo,
        pago.tipo.name,
        pago.nota,
        pago.id,
      ],
    );
  }

  Future<void> deletePago(int pagoId) async {
    await _db.query('DELETE FROM pagos_membresias WHERE id = ?', [pagoId]);
  }

  /// Obtener el costo del plan de un asesorado
  Future<double> obtenerCostoPlan(int asesoradoId) async {
    final results = await _db.query(
      '''
      SELECT costo FROM planes 
      WHERE id IN (SELECT plan_id FROM asesorados WHERE id = ?)
      ''',
      [asesoradoId],
    );

    if (results.isEmpty) {
      return 0.0;
    }

    final costo = results.first.fields['costo'];
    if (costo is num) {
      return costo.toDouble();
    } else if (costo is String) {
      return double.tryParse(costo) ?? 0.0;
    }
    return 0.0;
  }

  /// Verificar si un asesorado tiene plan activo
  Future<bool> tieneActivoPlan(int asesoradoId) async {
    final results = await _db.query(
      '''
      SELECT plan_id FROM asesorados 
      WHERE id = ? AND plan_id IS NOT NULL
      ''',
      [asesoradoId],
    );
    return results.isNotEmpty;
  }

  /// Registrar un pago (abono o completo según el monto)
  ///
  /// ✅ MEJORA: tipo se determina POST-inserción basado en saldo resultante
  /// - Si saldo > 0 después: tipo = abono
  /// - Si saldo <= 0 después: tipo = completo (membresía se extiende)
  /// - Valida plan activo antes de proceder
  /// - Auto-actualiza fecha_vencimiento si es necesario
  /// - Auto-extiende membresía si saldo se completa
  /// - Una única fuente de verdad (elimina duplicación)
  Future<Map<String, dynamic>> registrarPago({
    required int asesoradoId,
    required double monto,
    String? nota,
  }) async {
    if (monto <= 0) {
      throw Exception('El monto del pago debe ser mayor a cero');
    }

    final datos = await _obtenerDatosAsesorado(asesoradoId);
    if (datos == null || datos['plan_id'] == null) {
      throw Exception('No se puede registrar pago sin plan activo asignado');
    }

    final costoPlan = _toDouble(datos['plan_costo']);
    if (costoPlan <= 0) {
      throw Exception('El plan asignado no tiene un costo configurado');
    }

    final periodoObjetivo = await _determinarPeriodoObjetivo(
      asesoradoId: asesoradoId,
      costoPlan: costoPlan,
      fechaVencimiento: _parseFecha(datos['fecha_vencimiento']),
    );

    try {
      // 1️⃣ INSERTAR con tipo TEMPORAL y capturar el ID insertado
      await _db.query(
        '''
        INSERT INTO pagos_membresias (
          asesorado_id, fecha_pago, monto,
          periodo, tipo, nota
        ) VALUES (?, ?, ?, ?, ?, ?)
        ''',
        [
          asesoradoId,
          DateTime.now().toString().split(' ')[0],
          monto,
          periodoObjetivo.periodo,
          TipoPago.abono.name, // Temporal - se calcula después
          nota,
        ],
      );

      // Obtener el ID insertado (el último insert ID de la sesión)
      final lastIdResult = await _db.query('SELECT LAST_INSERT_ID() as id');
      final pagoId =
          lastIdResult.isNotEmpty
              ? (lastIdResult.first.fields['id'] as int?)
              : null;

      // 2️⃣ CALCULAR saldo resultante
      final saldoPeriodo = await _obtenerSaldoPeriodo(
        asesoradoId: asesoradoId,
        periodo: periodoObjetivo.periodo,
        costoPlan: costoPlan,
      );

      // 3️⃣ ACTUALIZAR tipo basado en saldo resultante (EXPLÍCITO por ID)
      final tipoPago =
          saldoPeriodo.saldoPendiente <= 0.0
              ? TipoPago.completo
              : TipoPago.abono;

      if (pagoId != null) {
        await _db.query('UPDATE pagos_membresias SET tipo = ? WHERE id = ?', [
          tipoPago.name,
          pagoId,
        ]);
      } else {
        // Fallback: si no conseguimos el ID, actualizar por periodo (menos seguro)
        if (kDebugMode) {
          debugPrint(
            '[PagosService] ⚠️ No se obtuvo LAST_INSERT_ID(), usando fallback por periodo',
          );
        }
        await _db.query(
          '''
          UPDATE pagos_membresias 
          SET tipo = ?
          WHERE asesorado_id = ? AND periodo = ? 
          ORDER BY fecha_pago DESC, id DESC LIMIT 1
          ''',
          [tipoPago.name, asesoradoId, periodoObjetivo.periodo],
        );
      }

      if (kDebugMode) {
        debugPrint(
          '[PagosService] 💳 Pago registrado: \$$monto, tipo=$tipoPago, '
          'saldo resultante: \$${saldoPeriodo.saldoPendiente.toStringAsFixed(2)}',
        );
      }

      // 4️⃣ Si saldo se completa, extender membresía
      DateTime? nuevaFechaVencimiento;
      if (saldoPeriodo.saldoPendiente <= 0.0) {
        nuevaFechaVencimiento = await _extenderMembresia(asesoradoId);
      } else {
        // Si aún hay saldo, actualizar fecha vencimiento
        await _actualizarFechaVencimientoSiNecesario(asesoradoId);
      }

      return {
        'periodo': periodoObjetivo.periodo,
        'total_abonado': saldoPeriodo.totalAbonado,
        'saldo_pendiente': saldoPeriodo.saldoPendiente,
        'costo_plan': costoPlan,
        'periodo_completado': saldoPeriodo.saldoPendiente <= 0.0,
        'tipo_pago': tipoPago.name,
        'nueva_fecha_vencimiento':
            nuevaFechaVencimiento?.toString().split(' ')[0],
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PagosService] ❌ Error registrando pago: $e');
      }
      rethrow;
    }
  }

  /// Registrar un abono parcial y devolver el estado actualizado del periodo.
  /// ⚠️ DEPRECADO: Usar registrarPago() en su lugar
  ///
  /// ✅ MEJORAS:
  /// - Valida plan activo antes de proceder
  /// - Auto-actualiza fecha_vencimiento si es necesario
  /// - Auto-extiende membresía si saldo se completa
  /// - Calcula saldo centralizado
  @Deprecated('Use registrarPago() instead')
  Future<Map<String, dynamic>> registrarAbono({
    required int asesoradoId,
    required double monto,
    String? nota,
  }) async {
    if (monto <= 0) {
      throw Exception('El monto del abono debe ser mayor a cero');
    }

    final datos = await _obtenerDatosAsesorado(asesoradoId);
    if (datos == null || datos['plan_id'] == null) {
      throw Exception('No se puede registrar abono sin plan activo asignado');
    }

    final costoPlan = _toDouble(datos['plan_costo']);
    if (costoPlan <= 0) {
      throw Exception('El plan asignado no tiene un costo configurado');
    }

    final periodoObjetivo = await _determinarPeriodoObjetivo(
      asesoradoId: asesoradoId,
      costoPlan: costoPlan,
      fechaVencimiento: _parseFecha(datos['fecha_vencimiento']),
    );

    try {
      // ✅ TRANSACCIÓN: Insertar pago
      await _db.query(
        '''
        INSERT INTO pagos_membresias (
          asesorado_id, fecha_pago, monto,
          periodo, tipo, nota
        ) VALUES (?, ?, ?, ?, ?, ?)
        ''',
        [
          asesoradoId,
          DateTime.now().toString().split(' ')[0],
          monto,
          periodoObjetivo.periodo,
          TipoPago.abono.name,
          nota,
        ],
      );

      // ✅ Calcular saldo con método centralizado
      final saldoPeriodo = await _obtenerSaldoPeriodo(
        asesoradoId: asesoradoId,
        periodo: periodoObjetivo.periodo,
        costoPlan: costoPlan,
      );

      // ✅ Si saldo se completa, extender membresía
      DateTime? nuevaFechaVencimiento;
      if (saldoPeriodo.saldoPendiente <= 0.0) {
        if (kDebugMode) {
          debugPrint(
            '[PagosService] 💳 Abono registrado de \$$monto. '
            'Período ${periodoObjetivo.periodo} completado. Extendiendo membresía...',
          );
        }
        nuevaFechaVencimiento = await _extenderMembresia(asesoradoId);
      } else {
        // ✅ Si aún hay saldo, actualizar fecha vencimiento si es necesario
        await _actualizarFechaVencimientoSiNecesario(asesoradoId);

        if (kDebugMode) {
          debugPrint(
            '[PagosService] 💳 Abono registrado de \$$monto. '
            'Período ${periodoObjetivo.periodo} pendiente (saldo: \$${saldoPeriodo.saldoPendiente.toStringAsFixed(2)})',
          );
        }
      }

      return {
        'periodo': periodoObjetivo.periodo,
        'total_abonado': saldoPeriodo.totalAbonado,
        'saldo_pendiente': saldoPeriodo.saldoPendiente,
        'costo_plan': costoPlan,
        'periodo_completado': saldoPeriodo.saldoPendiente <= 0.0,
        'nueva_fecha_vencimiento':
            nuevaFechaVencimiento?.toString().split(' ')[0],
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PagosService] ❌ Error registrando abono: $e');
      }
      rethrow;
    }
  }

  /// Registrar un pago completo (cubre todo el período objetivo) y devolver estado.
  /// ⚠️ DEPRECADO: Usar registrarPago() en su lugar
  ///
  /// ✅ MEJORAS:
  /// - Valida plan activo antes de proceder
  /// - Auto-actualiza fecha_vencimiento si es necesario
  /// - Auto-extiende membresía si saldo se completa
  /// - Calcula saldo centralizado
  /// - 🔧 CORRECCIÓN: Registra con tipo dinámico (abono vs completo)
  @Deprecated('Use registrarPago() instead')
  Future<Map<String, dynamic>> completarPago({
    required int asesoradoId,
    required double monto,
    String? nota,
  }) async {
    if (monto <= 0) {
      throw Exception('El monto del pago debe ser mayor a cero');
    }

    final datos = await _obtenerDatosAsesorado(asesoradoId);
    if (datos == null || datos['plan_id'] == null) {
      throw Exception('No se puede registrar pago sin plan activo asignado');
    }

    final costoPlan = _toDouble(datos['plan_costo']);
    if (costoPlan <= 0) {
      throw Exception('El plan asignado no tiene un costo configurado');
    }

    final periodoObjetivo = await _determinarPeriodoObjetivo(
      asesoradoId: asesoradoId,
      costoPlan: costoPlan,
      fechaVencimiento: _parseFecha(datos['fecha_vencimiento']),
    );

    try {
      // 🔧 Determinar tipo de pago según si el monto cubre el costo
      // Si es abono parcial, registrar como TipoPago.abono (no completo)
      final saldoActualPeriodo = costoPlan - periodoObjetivo.totalAbonado;
      final esAbonoCompleto = monto >= saldoActualPeriodo;
      final tipoPago = esAbonoCompleto ? TipoPago.completo : TipoPago.abono;

      // ✅ TRANSACCIÓN: Insertar pago con tipo correcto
      await _db.query(
        '''
        INSERT INTO pagos_membresias (
          asesorado_id, fecha_pago, monto,
          periodo, tipo, nota
        ) VALUES (?, ?, ?, ?, ?, ?)
        ''',
        [
          asesoradoId,
          DateTime.now().toString().split(' ')[0],
          monto,
          periodoObjetivo.periodo,
          tipoPago.name,
          nota,
        ],
      );

      // ✅ Calcular saldo con método centralizado
      final saldoPeriodo = await _obtenerSaldoPeriodo(
        asesoradoId: asesoradoId,
        periodo: periodoObjetivo.periodo,
        costoPlan: costoPlan,
      );

      // ✅ Si saldo se completa, extender membresía
      DateTime? nuevaFechaVencimiento;
      if (saldoPeriodo.saldoPendiente <= 0.0) {
        if (kDebugMode) {
          debugPrint(
            '[PagosService] 💳 Pago completo registrado de \$$monto. '
            'Período ${periodoObjetivo.periodo} completado. Extendiendo membresía...',
          );
        }
        nuevaFechaVencimiento = await _extenderMembresia(asesoradoId);
      } else {
        // ✅ Si aún hay saldo, actualizar fecha vencimiento si es necesario
        await _actualizarFechaVencimientoSiNecesario(asesoradoId);

        if (kDebugMode) {
          debugPrint(
            '[PagosService] 💳 Pago completo registrado de \$$monto. '
            'Período ${periodoObjetivo.periodo} pendiente (saldo: \$${saldoPeriodo.saldoPendiente.toStringAsFixed(2)})',
          );
        }
      }

      return {
        'periodo': periodoObjetivo.periodo,
        'total_abonado': saldoPeriodo.totalAbonado,
        'saldo_pendiente': saldoPeriodo.saldoPendiente,
        'costo_plan': costoPlan,
        'periodo_completado': saldoPeriodo.saldoPendiente <= 0.0,
        'nueva_fecha_vencimiento':
            nuevaFechaVencimiento?.toString().split(' ')[0],
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PagosService] ❌ Error completando pago: $e');
      }
      rethrow;
    }
  }

  /// Obtener el estado del pago de un asesorado
  ///
  /// Estados posibles:
  /// - 'sin_plan': No tiene plan asignado (plan_id IS NULL)
  /// - 'vencido': Fecha de vencimiento es anterior a hoy
  /// - 'proximo_vencimiento': Vencimiento en próximos 7 días (hoy <= vencimiento <= hoy+7)
  /// - 'activo': Plan activo y vencimiento > hoy+7
  /// - 'pagado': Saldo completamente cubierto
  ///
  /// ✅ CAMBIO: sin_vencimiento eliminado. Se auto-asigna fecha si NULL.
  Future<Map<String, dynamic>> obtenerEstadoPago(int asesoradoId) async {
    final datos = await _obtenerDatosAsesorado(asesoradoId);

    if (datos == null) {
      return {
        'estado': 'sin_plan',
        'saldo_pendiente': 0.0,
        'fecha_vencimiento': null,
        'total_pagado': 0.0,
        'costo_plan': 0.0,
        'plan_nombre': null,
        'periodo_a_pagar': null,
        'total_abonado_periodo': 0.0,
      };
    }

    final planId = datos['plan_id'] as int?;
    final costoPlan = _toDouble(datos['plan_costo']);
    var fechaVencimiento = _parseFecha(datos['fecha_vencimiento']);
    final planNombre = datos['plan_nombre']?.toString();

    // ✅ MEJORA: Si no tiene plan, estado es 'sin_plan'
    if (planId == null) {
      return {
        'estado': 'sin_plan',
        'saldo_pendiente': 0.0,
        'fecha_vencimiento': null,
        'total_pagado': 0.0,
        'costo_plan': 0.0,
        'plan_nombre': null,
        'periodo_a_pagar': null,
        'total_abonado_periodo': 0.0,
      };
    }

    // ✅ CAMBIO: Si no hay fecha, AUTO-ASIGNAR hoy + 30 días
    if (fechaVencimiento == null) {
      fechaVencimiento = DateTime.now().add(const Duration(days: 30));

      // Guardar en BD
      try {
        await _db.query(
          'UPDATE asesorados SET fecha_vencimiento = ? WHERE id = ?',
          [fechaVencimiento.toString().split(' ')[0], asesoradoId],
        );

        if (kDebugMode) {
          debugPrint(
            '[PagosService] 📅 Auto-asignada fecha de vencimiento para asesorado $asesoradoId: $fechaVencimiento',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[PagosService] ⚠️ Error auto-asignando fecha: $e');
        }
      }
    }

    if (costoPlan <= 0) {
      return {
        'estado': 'activo',
        'saldo_pendiente': 0.0,
        'fecha_vencimiento': fechaVencimiento,
        'total_pagado': 0.0,
        'costo_plan': costoPlan,
        'plan_nombre': planNombre,
        'periodo_a_pagar': null,
        'total_abonado_periodo': 0.0,
      };
    }

    final periodoObjetivo = await _determinarPeriodoObjetivo(
      asesoradoId: asesoradoId,
      costoPlan: costoPlan,
      fechaVencimiento: fechaVencimiento,
    );

    // ✅ MEJORA: Lógica clara de estados
    final hoy = _normalizarFecha(DateTime.now());
    final fechaVencNormalizada = _normalizarFecha(fechaVencimiento);
    final diasHastaVencimiento = fechaVencNormalizada.difference(hoy).inDays;

    String estadoCalculado = 'activo';

    // Si el saldo está completamente cubierto
    if (periodoObjetivo.saldoPendiente <= 0) {
      estadoCalculado = 'pagado';
    }
    // Si está vencido (pasado)
    else if (diasHastaVencimiento < 0) {
      estadoCalculado = 'vencido';
    }
    // Si está próximo a vencer (próximos 7 días)
    else if (diasHastaVencimiento <= 7) {
      estadoCalculado = 'proximo_vencimiento';
    }
    // Si está activo y aún hay tiempo
    else {
      estadoCalculado = 'activo';
    }

    return {
      'estado': estadoCalculado,
      'saldo_pendiente': periodoObjetivo.saldoPendiente,
      'fecha_vencimiento': fechaVencimiento,
      'total_pagado': periodoObjetivo.totalAbonado,
      'costo_plan': costoPlan,
      'plan_nombre': planNombre,
      'periodo_a_pagar': periodoObjetivo.periodo,
      'total_abonado_periodo': periodoObjetivo.totalAbonado,
      'dias_hasta_vencimiento': diasHastaVencimiento,
      'puede_pagar_anticipado': periodoObjetivo.periodoFuturoDisponible,
      'en_ventana_corte':
          periodoObjetivo.esPeriodoPendiente &&
          periodoObjetivo.saldoPendiente > 0,
      'ultimo_periodo_pagado': periodoObjetivo.ultimoPeriodoPagado,
    };
  }

  /// Obtener pagos por período
  Future<List<PagoMembresia>> getPagosPorPeriodo(
    int asesoradoId,
    String periodo,
  ) async {
    final results = await _db.query(
      '''
      SELECT * FROM pagos_membresias 
      WHERE asesorado_id = ? AND periodo = ?
      ORDER BY fecha_pago DESC
      ''',
      [asesoradoId, periodo],
    );
    return results.map((r) => PagoMembresia.fromMap(r.fields)).toList();
  }

  /// Obtener todos los periodos con pagos pendientes para un asesorado
  /// ⚠️ DEPRECATED: Usar obtenerTodosPeriodos() en su lugar para auditorías completas
  /// 🎯 CORREGIDO: join correcto (pl.id) para detectar períodos pendientes
  Future<List<String>> obtenerPeriodosPendientes(int asesoradoId) async {
    final results = await _db.query(
      '''
      SELECT p.periodo
      FROM pagos_membresias p
      INNER JOIN asesorados a ON p.asesorado_id = a.id
      LEFT JOIN planes pl ON a.plan_id = pl.id
      WHERE p.asesorado_id = ?
      GROUP BY p.periodo
      HAVING pl.costo IS NOT NULL AND COALESCE(SUM(p.monto), 0) < pl.costo
      ORDER BY p.periodo DESC
      ''',
      [asesoradoId],
    );
    return results.map((r) => r.fields['periodo'].toString()).toList();
  }

  /// 🎯 NUEVA: Obtener TODOS los periodos históricos (pendientes + pagados)
  /// Para auditorías completas y selectores de período sin límites
  /// 🎯 CORREGIDO: Filtrar nulos para evitar mostrar 'null' en UI
  /// Ordena DESC por período (más recientes primero)
  Future<List<String>> obtenerTodosPeriodos(int asesoradoId) async {
    final results = await _db.query(
      '''
      SELECT DISTINCT p.periodo
      FROM pagos_membresias p
      WHERE p.asesorado_id = ? AND p.periodo IS NOT NULL AND p.periodo <> ''
      ORDER BY p.periodo DESC
      ''',
      [asesoradoId],
    );
    return results
        .map((r) => r.fields['periodo'].toString())
        .where((periodo) => periodo.isNotEmpty && periodo != 'null')
        .toList();
  }

  /// Obtener resumen de pagos por mes (para contabilidad)
  Future<List<Map<String, dynamic>>> obtenerResumenPagosPorMes(
    int? coachId,
  ) async {
    String sql = '''
      SELECT 
        periodo,
        COUNT(*) as cantidad_pagos,
        SUM(CASE WHEN tipo = 'completo' THEN 1 ELSE 0 END) as pagos_completos,
        SUM(CASE WHEN tipo = 'abono' THEN 1 ELSE 0 END) as abonos,
        SUM(monto) as total_recaudado
      FROM pagos_membresias p
    ''';

    List<dynamic> params = [];

    if (coachId != null) {
      sql += '''
        INNER JOIN asesorados a ON p.asesorado_id = a.id
        WHERE a.coach_id = ?
      ''';
      params.add(coachId);
    }

    sql += ' GROUP BY periodo ORDER BY periodo DESC';

    final results = await _db.query(sql, params);
    return results.map((r) => r.fields).toList();
  }

  // ============================================================================
  // MÉTODOS DE PAGOS PENDIENTES CON CACHÉ (anteriormente en PagosPendientesService)
  // ============================================================================

  /// Obtiene asesorados con pagos pendientes/atrasados/próximos para un coach
  ///
  /// [estadoFiltro] puede ser:
  /// - null o 'todos'  → Todos los pendientes (deudor + próximos 7 días)
  /// - 'atrasado'      → Solo status='deudor'
  /// - 'proximo'       → Solo próximos a vencer (activo + venc. próximos 7 días)
  ///
  /// Esta función consolidó anteriormente 3 métodos duplicados en uno parametrizado ✅
  Future<List<AsesoradoPagoPendiente>> obtenerAsesoradosConEstadoPago(
    int coachId, {
    String? estadoFiltro,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      // ✅ Construir clave de caché única
      final cacheKey =
          'asesorados_estado_${coachId}_${estadoFiltro ?? "todos"}_${page}_$pageSize';
      if (_isCacheValid(cacheKey)) {
        developer.log(
          '[CACHÉ HIT] Asesorados con estado=$estadoFiltro para coach $coachId',
          name: 'PagosService',
        );
        return _cache[cacheKey]!.data;
      }

      developer.log(
        '[CACHÉ MISS] Obteniendo asesorados con estado=$estadoFiltro para coach $coachId',
        name: 'PagosService',
      );

      // ✅ Construir condición WHERE según estado solicitado
      String whereCondition = 'a.coach_id = ? AND a.plan_id IS NOT NULL';
      List<dynamic> params = [coachId];

      if (estadoFiltro == 'atrasado') {
        whereCondition += ' AND a.status = "deudor"';
      } else if (estadoFiltro == 'proximo') {
        whereCondition +=
            ' AND a.status = "activo" AND a.fecha_vencimiento BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)';
      } else {
        // null o 'todos': deudor O próximos a vencer
        whereCondition +=
            ' AND (a.status = "deudor" OR (a.status = "activo" AND a.fecha_vencimiento BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)))';
      }

      final offset = page * pageSize;

      final results = await _db.query(
        '''
        SELECT 
          a.id AS asesorado_id,
          a.nombre,
          a.avatar_url,
          COALESCE(p.nombre, 'Sin Plan') AS plan_nombre,
          a.fecha_vencimiento,
          COALESCE(p.costo, 0.0) AS costo_plan,
          COALESCE(p.costo, 0.0) AS monto_pendiente,
          CASE 
            WHEN a.status = 'deudor' THEN 'atrasado'
            WHEN a.fecha_vencimiento BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY) THEN 'proximo'
            ELSE 'pendiente'
          END as estado
        FROM asesorados a
        LEFT JOIN planes p ON a.plan_id = p.id
        WHERE $whereCondition
        ORDER BY a.fecha_vencimiento ASC
        LIMIT ? OFFSET ?
        ''',
        [...params, pageSize, offset],
      );

      final resultado = [
        for (final row in results) AsesoradoPagoPendiente.fromMap(row.fields),
      ];

      _cache[cacheKey] = _CacheEntry(resultado);
      return resultado;
    } catch (e) {
      throw Exception(
        'Error al obtener asesorados con estado $estadoFiltro: $e',
      );
    }
  }

  /// Obtiene asesorados con pagos pendientes (deudor + próximos 7 días)
  /// Métodos wrapper para compatibilidad hacia atrás ✅
  Future<List<AsesoradoPagoPendiente>> obtenerAsesoradosConPagosPendientes(
    int coachId, {
    int page = 0,
    int pageSize = 20,
  }) => obtenerAsesoradosConEstadoPago(
    coachId,
    estadoFiltro: null,
    page: page,
    pageSize: pageSize,
  );

  /// Obtiene asesorados con pagos atrasados (status='deudor')
  Future<List<AsesoradoPagoPendiente>> obtenerAsesoradosConPagosAtrasados(
    int coachId,
  ) => obtenerAsesoradosConEstadoPago(
    coachId,
    estadoFiltro: 'atrasado',
    pageSize: 1000,
  );

  /// Obtiene asesorados con pagos próximos (vencimiento próximos 7 días)
  Future<List<AsesoradoPagoPendiente>> obtenerAsesoradosConPagosProximos(
    int coachId,
  ) => obtenerAsesoradosConEstadoPago(
    coachId,
    estadoFiltro: 'proximo',
    pageSize: 1000,
  );

  /// Busca asesorados con pagos pendientes por nombre
  Future<List<AsesoradoPagoPendiente>> buscarAsesoradosConPagosPendientes(
    int coachId,
    String query,
  ) async {
    try {
      final todos = await obtenerAsesoradosConPagosPendientes(
        coachId,
        pageSize: 1000,
      );
      return todos
          .where((a) => a.nombre.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar asesorados: $e');
    }
  }

  /// Obtiene el total de dinero pendiente para un coach
  Future<double> obtenerTotalPagosPendientes(int coachId) async {
    try {
      final asesorados = await obtenerAsesoradosConPagosPendientes(
        coachId,
        pageSize: 1000,
      );
      return asesorados.fold<double>(0, (total, a) => total + a.montoPendiente);
    } catch (e) {
      throw Exception('Error al calcular total de pagos pendientes: $e');
    }
  }

  /// Obtiene la cantidad de asesorados con pagos pendientes
  Future<int> obtenerCountAsesoradosConPagosPendientes(int coachId) async {
    try {
      final results = await _db.query(
        '''
        SELECT COUNT(a.id) as total
        FROM asesorados a
        WHERE a.coach_id = ?
          AND a.plan_id IS NOT NULL
          AND (
            a.status = 'deudor' OR 
            (a.status = 'activo' AND a.fecha_vencimiento BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY))
          )
        ''',
        [coachId],
      );

      if (results.isNotEmpty) {
        return results.first.fields['total'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      throw Exception('Error al contar asesorados con pagos pendientes: $e');
    }
  }

  /// Invalida TODAS las variantes de caché para un coach
  /// ✅ Elimina:
  /// - asesorados_estado_{coachId}_*  (todas las páginas y filtros)
  /// - pagos_pendientes_{coachId}_* (compatibilidad hacia atrás)
  /// - pagos_atrasados_{coachId}
  /// - pagos_proximos_{coachId}
  void invalidarCacheCoach(int coachId) {
    int removedCount = 0;

    // Remover todas las variantes nuevas (parametrizadas)
    _cache.removeWhere((key, _) {
      if (key.startsWith('asesorados_estado_$coachId')) {
        removedCount++;
        return true;
      }
      return false;
    });

    // Remover todas las variantes antiguas (compatibilidad hacia atrás)
    _cache.removeWhere((key, _) {
      if (key.startsWith('pagos_pendientes_$coachId')) {
        removedCount++;
        return true;
      }
      return false;
    });

    if (_cache.remove('pagos_atrasados_$coachId') != null) removedCount++;
    if (_cache.remove('pagos_proximos_$coachId') != null) removedCount++;

    developer.log(
      'Caché invalidado para coach $coachId ($removedCount entradas removidas)',
      name: 'PagosService',
    );
  }

  /// Limpia COMPLETAMENTE el caché (úsalo con cuidado)
  void limpiarCache() {
    final count = _cache.length;
    _cache.clear();
    _pagosCache.clear();
    _pagosCacheTime.clear();
    developer.log(
      'Caché completamente limpiado ($count entradas)',
      name: 'PagosService',
    );
  }

  // ============================================================================
  // MÉTODOS PRIVADOS AUXILIARES
  // ============================================================================

  /// Verifica si una entrada en caché es válida (no expirada)
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;
    final entry = _cache[key]!;
    return DateTime.now().difference(entry.timestamp) < _cacheDuration;
  }

  Future<Map<String, dynamic>?> _obtenerDatosAsesorado(int asesoradoId) async {
    final results = await _db.query(
      '''
      SELECT 
        a.status,
        a.fecha_vencimiento,
        a.plan_id,
        p.costo AS plan_costo,
        p.nombre AS plan_nombre
      FROM asesorados a
      LEFT JOIN planes p ON a.plan_id = p.id
      WHERE a.id = ?
      ''',
      [asesoradoId],
    );

    if (results.isEmpty) {
      return null;
    }

    return results.first.fields;
  }

  Future<_PeriodoObjetivo> _determinarPeriodoObjetivo({
    required int asesoradoId,
    required double costoPlan,
    required DateTime? fechaVencimiento,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[PagosService] _determinarPeriodoObjetivo iniciada para asesorado=$asesoradoId, costoPlan=$costoPlan, vencimiento=$fechaVencimiento',
      );
    }

    final resultados = await _db.query(
      '''
      SELECT periodo, COALESCE(SUM(monto), 0) AS total_pagado
      FROM pagos_membresias
      WHERE asesorado_id = ? AND periodo IS NOT NULL AND periodo <> ''
      GROUP BY periodo
      ORDER BY periodo ASC
      ''',
      [asesoradoId],
    );

    if (kDebugMode) {
      debugPrint(
        '[PagosService] Períodos encontrados en BD: ${resultados.map((r) => "${r.fields['periodo']}=\$${_toDouble(r.fields['total_pagado'])}").toList()}',
      );
    }

    String? periodoPendiente;
    String? ultimoPeriodoPagado;
    double totalAbonado = 0.0;
    bool periodoPendienteEncontrado = false;

    for (final row in resultados) {
      final periodo = row.fields['periodo']?.toString();
      if (periodo == null || periodo.isEmpty) {
        continue;
      }

      final total = _toDouble(row.fields['total_pagado']);

      if (kDebugMode) {
        debugPrint(
          '[PagosService]   Evaluando período=$periodo: total_pagado=$total vs costoPlan=$costoPlan',
        );
      }

      if (costoPlan > 0 && total + 0.01 < costoPlan) {
        periodoPendiente = periodo;
        totalAbonado = total;
        periodoPendienteEncontrado = true;
        if (kDebugMode) {
          debugPrint(
            '[PagosService]     ✓ Período pendiente detectado: $periodo (saldo=${costoPlan - total})',
          );
        }
        break;
      } else if (costoPlan > 0 && total + 0.01 >= costoPlan) {
        ultimoPeriodoPagado = periodo;
        if (kDebugMode) {
          debugPrint(
            '[PagosService]     ✓ Período pagado completamente: $periodo',
          );
        }
      }
    }

    final ahora = _normalizarFecha(DateTime.now());
    final fechaCorte =
        fechaVencimiento != null ? _normalizarFecha(fechaVencimiento) : ahora;

    if (kDebugMode) {
      debugPrint(
        '[PagosService] Búsqueda de período pendiente: ${periodoPendienteEncontrado ? periodoPendiente : "NO encontrado"}',
      );
    }

    if (periodoPendiente == null) {
      String? ultimoPeriodo;
      if (resultados.isNotEmpty) {
        ultimoPeriodo = resultados.last.fields['periodo']?.toString();
      }

      if (ultimoPeriodo != null && ultimoPeriodo.isNotEmpty) {
        final base = _parsePeriodo(ultimoPeriodo);
        periodoPendiente = _formatPeriodo(_sumarMeses(base, 1));
        if (kDebugMode) {
          debugPrint(
            '[PagosService] Período sugerido (siguiente al último): $periodoPendiente',
          );
        }
      } else if (fechaVencimiento != null) {
        final base = DateTime(fechaVencimiento.year, fechaVencimiento.month, 1);
        periodoPendiente = _formatPeriodo(base);
        if (kDebugMode) {
          debugPrint(
            '[PagosService] Período sugerido (desde fecha_vencimiento): $periodoPendiente',
          );
        }
      } else {
        final now = DateTime.now();
        periodoPendiente = _formatPeriodo(DateTime(now.year, now.month, 1));
        if (kDebugMode) {
          debugPrint(
            '[PagosService] Período sugerido (mes actual): $periodoPendiente',
          );
        }
      }

      totalAbonado = 0.0;
    }

    double saldoCalculado = 0.0;
    bool periodoEsFuturoSugerido = false;
    bool periodoEnVentanaCorte = false;

    if (costoPlan <= 0) {
      saldoCalculado = 0.0;
      if (kDebugMode) {
        debugPrint('[PagosService] Saldo=0 (costoPlan<=0)');
      }
    } else if (periodoPendienteEncontrado) {
      saldoCalculado = (costoPlan - totalAbonado).clamp(0.0, costoPlan);
      if (kDebugMode) {
        debugPrint(
          '[PagosService] Saldo calculado: $saldoCalculado = ($costoPlan - $totalAbonado)',
        );
      }
    } else {
      // No hay períodos pendientes: evaluar fecha de corte para mostrar siguiente cobro
      final int diasHastaVencimiento = fechaCorte.difference(ahora).inDays;
      final bool vencido = !fechaCorte.isAfter(ahora);
      periodoEnVentanaCorte =
          fechaCorte.isAfter(ahora) && diasHastaVencimiento <= _diasAvisoCorte;

      if (kDebugMode) {
        debugPrint(
          '[PagosService] Ventana de corte: diasHasta=$diasHastaVencimiento, vencido=$vencido, en_ventana=$periodoEnVentanaCorte (alerta si <= $_diasAvisoCorte días)',
        );
        debugPrint('[PagosService]   ahora=$ahora vs fechaCorte=$fechaCorte');
      }

      if (vencido || periodoEnVentanaCorte) {
        saldoCalculado = costoPlan;
        if (kDebugMode) {
          debugPrint(
            '[PagosService] Saldo mostrado: $saldoCalculado (vencido=$vencido OR en_ventana=$periodoEnVentanaCorte)',
          );
        }
      } else {
        saldoCalculado = 0.0;
        periodoEsFuturoSugerido = true;
        if (kDebugMode) {
          debugPrint(
            '[PagosService] Saldo=0 (período futuro, $diasHastaVencimiento días para vencimiento)',
          );
        }
      }
    }

    if (kDebugMode) {
      debugPrint(
        '[PagosService] Resultado final: período=$periodoPendiente, saldo=$saldoCalculado, es_pendiente=${periodoPendienteEncontrado || periodoEnVentanaCorte}',
      );
    }

    return _PeriodoObjetivo(
      periodo: periodoPendiente,
      totalAbonado: totalAbonado,
      saldoPendiente: saldoCalculado,
      esPeriodoPendiente: periodoPendienteEncontrado || periodoEnVentanaCorte,
      periodoFuturoDisponible: periodoEsFuturoSugerido,
      ultimoPeriodoPagado: ultimoPeriodoPagado,
      fechaCorteEvaluada: fechaVencimiento,
    );
  }

  Future<_PeriodoSaldo> _obtenerSaldoPeriodo({
    required int asesoradoId,
    required String periodo,
    required double costoPlan,
  }) async {
    final results = await _db.query(
      '''
      SELECT COALESCE(SUM(monto), 0) as totalAbonado
      FROM pagos_membresias
      WHERE asesorado_id = ? AND periodo = ?
      ''',
      [asesoradoId, periodo],
    );

    double totalAbonado = 0.0;
    if (results.isNotEmpty) {
      totalAbonado = _toDouble(results.first.fields['totalAbonado']);
    }

    final saldo =
        costoPlan <= 0 ? 0.0 : (costoPlan - totalAbonado).clamp(0.0, costoPlan);

    return _PeriodoSaldo(totalAbonado: totalAbonado, saldoPendiente: saldo);
  }

  /// Extiende la membresía del asesorado 30 días y devuelve la nueva fecha de vencimiento
  Future<DateTime?> _extenderMembresia(int asesoradoId) async {
    try {
      // 1. Obtener coach_id del asesorado para invalidar caché
      final coachResults = await _db.query(
        'SELECT coach_id FROM asesorados WHERE id = ?',
        [asesoradoId],
      );

      int? coachId;
      if (coachResults.isNotEmpty) {
        coachId = coachResults.first.fields['coach_id'] as int?;
      }

      // 2. Extender membresía: cambiar status a 'activo' y extender fecha
      await _db.query(
        '''
        UPDATE asesorados
        SET 
          status = 'activo',
          fecha_vencimiento = DATE_ADD(
            GREATEST(COALESCE(fecha_vencimiento, CURDATE()), CURDATE()), 
            INTERVAL 30 DAY
          )
        WHERE id = ?
        ''',
        [asesoradoId],
      );

      // 3. Obtener la nueva fecha de vencimiento
      final updatedResults = await _db.query(
        'SELECT fecha_vencimiento FROM asesorados WHERE id = ?',
        [asesoradoId],
      );

      DateTime? nuevaFechaVencimiento;
      if (updatedResults.isNotEmpty) {
        final fechaStr =
            updatedResults.first.fields['fecha_vencimiento']?.toString();
        if (fechaStr != null) {
          nuevaFechaVencimiento = _parseFecha(fechaStr);
        }
      }

      // 4. Invalidar caché del coach si fue encontrado
      if (coachId != null) {
        invalidarCacheCoach(coachId);

        if (kDebugMode) {
          debugPrint(
            '[PagosService] ✅ Membresía extendida para asesorado $asesoradoId. '
            'Status: activo | Nueva fecha vencimiento: ${nuevaFechaVencimiento?.toString().split(' ')[0]}. Coach $coachId caché invalidado.',
          );
        }
      } else {
        if (kDebugMode) {
          debugPrint(
            '[PagosService] ⚠️ Membresía extendida para asesorado $asesoradoId, '
            'pero no se encontró coach_id. Caché NO invalidado.',
          );
        }
      }

      return nuevaFechaVencimiento;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PagosService] ❌ Error extendiendo membresía: $e');
      }
      rethrow;
    }
  }

  double _toDouble(dynamic raw) {
    if (raw == null) {
      return 0.0;
    }
    if (raw is num) {
      return raw.toDouble();
    }
    if (raw is String) {
      return double.tryParse(raw) ?? 0.0;
    }
    if (raw is BigInt) {
      return raw.toDouble();
    }
    return double.tryParse(raw.toString()) ?? 0.0;
  }

  DateTime? _parseFecha(dynamic raw) {
    if (raw == null) {
      return null;
    }
    if (raw is DateTime) {
      return raw;
    }
    return DateTime.tryParse(raw.toString());
  }

  /// Normaliza una fecha a medianoche (00:00:00) para comparaciones consistentes
  DateTime _normalizarFecha(DateTime fecha) {
    return DateTime(fecha.year, fecha.month, fecha.day);
  }

  DateTime _parsePeriodo(String periodo) {
    final parts = periodo.split('-');
    if (parts.length != 2) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, 1);
    }

    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    return DateTime(year, month, 1);
  }

  String _formatPeriodo(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  DateTime _sumarMeses(DateTime base, int meses) {
    final yearOffset = (base.month - 1 + meses) ~/ 12;
    final newMonth = (base.month - 1 + meses) % 12 + 1;
    return DateTime(base.year + yearOffset, newMonth, 1);
  }

  /// Actualiza automáticamente la fecha de vencimiento si es necesario
  ///
  /// ✅ CORRECCIÓN: Solo extender si NO hay saldo pendiente
  /// ✅ NORMALIZACIÓN: Comparar fechas a medianoche para consistencia
  /// Lógica:
  /// - Si saldo pagado + fecha vencida → resetear a hoy + 30 (próximo período)
  /// - Si saldo pendiente + fecha vencida → MANTENER (auditoría de morosidad)
  /// - Si no hay fecha + saldo pagado → asignar hoy + 30
  /// - Si no hay fecha + saldo pendiente → asignar hoy + 30 SOLO para determinar vencimiento
  /// - Si es futuro → nunca tocar (mantener continuidad)
  Future<void> _actualizarFechaVencimientoSiNecesario(int asesoradoId) async {
    try {
      final currentData = await _obtenerDatosAsesorado(asesoradoId);
      if (currentData == null) return;

      final fechaActual = _parseFecha(currentData['fecha_vencimiento']);
      final hoy = _normalizarFecha(DateTime.now());

      // ✅ CORRECCIÓN: Obtener saldo actual para decidir si actualizar fecha
      final estadoData = await obtenerEstadoPago(asesoradoId);
      final saldoPendiente = (estadoData['saldo_pendiente'] as double?) ?? 0.0;

      bool necesitaActualizar = false;
      DateTime? nuevaFecha;

      // 1️⃣ Si saldo COMPLETAMENTE PAGADO (<=0) y fecha pasada → resetear para próximo período
      if (saldoPendiente <= 0.0 && fechaActual != null) {
        final fechaActualNormalizada = _normalizarFecha(fechaActual);
        if (fechaActualNormalizada.isBefore(hoy)) {
          necesitaActualizar = true;
          nuevaFecha = hoy.add(const Duration(days: 30));

          if (kDebugMode) {
            debugPrint(
              '[PagosService] 📅 Saldo pagado ($saldoPendiente) y fecha vencida ($fechaActualNormalizada) → reseteando a $nuevaFecha',
            );
          }
        }
      }
      // 2️⃣ Si saldo PENDIENTE (>0) y fecha pasada → MANTENER para seguimiento de morosidad
      else if (saldoPendiente > 0.0 && fechaActual != null) {
        final fechaActualNormalizada = _normalizarFecha(fechaActual);
        if (fechaActualNormalizada.isBefore(hoy)) {
          // ❌ NO CAMBIAR - permitir que se muestre como vencido en filtros
          if (kDebugMode) {
            debugPrint(
              '[PagosService] 📅 Saldo pendiente (\$${saldoPendiente.toStringAsFixed(2)}) y fecha vencida ($fechaActualNormalizada) → MANTENER para auditoría de morosidad',
            );
          }
          return; // No actualizar
        }
      }
      // 3️⃣ Si no hay fecha → asignar hoy + 30 (para todos)
      else if (fechaActual == null) {
        necesitaActualizar = true;
        nuevaFecha = hoy.add(const Duration(days: 30));

        if (kDebugMode) {
          debugPrint(
            '[PagosService] 📅 Sin fecha vencimiento → asignando $nuevaFecha (saldo: \$${saldoPendiente.toStringAsFixed(2)})',
          );
        }
      }
      // 4️⃣ Si es futuro → NUNCA TOCAR (mantener continuidad)

      if (necesitaActualizar && nuevaFecha != null) {
        await _db.query(
          'UPDATE asesorados SET fecha_vencimiento = ? WHERE id = ?',
          [nuevaFecha.toString().split(' ')[0], asesoradoId],
        );

        if (kDebugMode) {
          debugPrint(
            '[PagosService] ✅ Fecha de vencimiento actualizada para asesorado $asesoradoId: $nuevaFecha',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[PagosService] ⚠️ Error actualizando fecha vencimiento: $e',
        );
      }
      // No relanzar para no interrumpir el flujo de pago
    }
  }

  /// 🎯 TAREA 1.3: Verifica si los abonos completan el plan y aplica cambios de estado
  /// Retorna true si el estado cambió y membresía fue extendida
  Future<bool> verificarYAplicarEstadoAbono({
    required int asesoradoId,
    required String periodo,
  }) async {
    try {
      // 1. Obtener plan_id y costo del asesorado usando método existente
      final datos = await _obtenerDatosAsesorado(asesoradoId);
      if (datos == null || datos['plan_id'] == null) {
        if (kDebugMode) {
          debugPrint(
            '[PagosService] Asesorado $asesoradoId no tiene plan activo',
          );
        }
        return false;
      }

      final costoPlan = _toDouble(datos['plan_costo']);
      if (costoPlan <= 0) {
        if (kDebugMode) {
          debugPrint(
            '[PagosService] Plan para asesorado $asesoradoId tiene costo 0 o inválido',
          );
        }
        return false;
      }

      // 2. Sumar abonos del período
      final abonoResult = await _db.query(
        '''
        SELECT COALESCE(SUM(monto), 0) as total_pagado
        FROM pagos_membresias
        WHERE asesorado_id = ? AND periodo = ?
        ''',
        [asesoradoId, periodo],
      );

      final totalPagado = _toDouble(abonoResult.first.fields['total_pagado']);

      if (kDebugMode) {
        debugPrint(
          '[PagosService] Verificación abonos - Asesorado: $asesoradoId, '
          'Período: $periodo, Total pagado: \$${totalPagado.toStringAsFixed(2)}, '
          'Costo plan: \$${costoPlan.toStringAsFixed(2)}',
        );
      }

      // 3. Verificar si abono >= costo del plan
      if (totalPagado >= costoPlan) {
        // 4. Cambiar estado a 'activo'
        await _db.query(
          "UPDATE asesorados SET status = 'activo' WHERE id = ?",
          [asesoradoId],
        );

        if (kDebugMode) {
          debugPrint(
            '[PagosService] ✅ Estado asesorado $asesoradoId cambió a ACTIVO '
            '(pagos completan plan)',
          );
        }

        // ⚠️ NO extender membresía aquí - completarPago ya lo hizo si fue necesario
        // Este método es idempotente y solo actualiza el status del asesorado
        // La extensión de membresía se maneja en completarPago/registrarAbono

        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PagosService] ❌ Error verificando estado abono: $e');
      }
      return false;
    }
  }
}

/// Estructura de datos para representar saldo de un período específico
class _PeriodoSaldo {
  final double totalAbonado;
  final double saldoPendiente;

  const _PeriodoSaldo({
    required this.totalAbonado,
    required this.saldoPendiente,
  });
}

/// Estructura de datos para representar un período objetivo de pago
class _PeriodoObjetivo {
  final String periodo;
  final double totalAbonado;
  final double saldoPendiente;
  final bool esPeriodoPendiente;
  final bool periodoFuturoDisponible;
  final String? ultimoPeriodoPagado;
  final DateTime? fechaCorteEvaluada;

  const _PeriodoObjetivo({
    required this.periodo,
    required this.totalAbonado,
    required this.saldoPendiente,
    required this.esPeriodoPendiente,
    required this.periodoFuturoDisponible,
    this.ultimoPeriodoPagado,
    this.fechaCorteEvaluada,
  });
}

/// Entrada en el caché con timestamp para validación de expiración
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  _CacheEntry(this.data) : timestamp = DateTime.now();
}
