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
class PagosService {
  final _db = DatabaseConnection.instance;
  static const int defaultPageSize = 10;

  // ============================================================================
  // SISTEMA DE CACHÉ (anteriormente en PagosPendientesService)
  // ============================================================================

  final Map<String, _CacheEntry<List<AsesoradoPagoPendiente>>> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  // 🛡️ MÓDULO 4: Error Handling - Cache mejorado para fallback
  final Map<int, List<PagoMembresia>> _pagosCache = {};
  final Map<int, DateTime> _pagosCacheTime = {};
  static const Duration _pagosCacheDuration = Duration(minutes: 10);

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

  /// Registrar un abono parcial y devolver el estado actualizado del periodo.
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

    final saldoPeriodo = await _obtenerSaldoPeriodo(
      asesoradoId: asesoradoId,
      periodo: periodoObjetivo.periodo,
      costoPlan: costoPlan,
    );

    // ✨ Si el saldo es 0 o negativo, extender membresía
    if (saldoPeriodo.saldoPendiente <= 0.0) {
      if (kDebugMode) {
        debugPrint(
          '[PagosService] 💳 Abono registrado de \$$monto. '
          'Período ${periodoObjetivo.periodo} completado (saldo: \$${saldoPeriodo.saldoPendiente.toStringAsFixed(2)}). '
          'Extendiendo membresía...',
        );
      }
      await _extenderMembresia(asesoradoId);
    } else {
      if (kDebugMode) {
        debugPrint(
          '[PagosService] 💳 Abono registrado de \$$monto. '
          'Período ${periodoObjetivo.periodo} pendiente (saldo restante: \$${saldoPeriodo.saldoPendiente.toStringAsFixed(2)})',
        );
      }
    }

    return {
      'periodo': periodoObjetivo.periodo,
      'total_abonado': saldoPeriodo.totalAbonado,
      'saldo_pendiente': saldoPeriodo.saldoPendiente,
      'costo_plan': costoPlan,
      'periodo_completado': saldoPeriodo.saldoPendiente <= 0.0,
    };
  }

  /// Registrar un pago completo (cubre todo el período objetivo) y devolver estado.
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
        TipoPago.completo.name,
        nota,
      ],
    );

    final saldoPeriodo = await _obtenerSaldoPeriodo(
      asesoradoId: asesoradoId,
      periodo: periodoObjetivo.periodo,
      costoPlan: costoPlan,
    );

    // ✨ Si el saldo es 0 o negativo, extender membresía
    if (saldoPeriodo.saldoPendiente <= 0.0) {
      if (kDebugMode) {
        debugPrint(
          '[PagosService] 💳 Pago completo registrado de \$$monto. '
          'Período ${periodoObjetivo.periodo} completado (saldo: \$${saldoPeriodo.saldoPendiente.toStringAsFixed(2)}). '
          'Extendiendo membresía...',
        );
      }
      await _extenderMembresia(asesoradoId);
    } else {
      if (kDebugMode) {
        debugPrint(
          '[PagosService] 💳 Pago completo registrado de \$$monto. '
          'Período ${periodoObjetivo.periodo} pendiente (saldo restante: \$${saldoPeriodo.saldoPendiente.toStringAsFixed(2)})',
        );
      }
    }

    return {
      'periodo': periodoObjetivo.periodo,
      'total_abonado': saldoPeriodo.totalAbonado,
      'saldo_pendiente': saldoPeriodo.saldoPendiente,
      'costo_plan': costoPlan,
      'periodo_completado': saldoPeriodo.saldoPendiente <= 0.0,
    };
  }

  /// Obtener el estado del pago de un asesorado (activo, pendiente, deudor)
  Future<Map<String, dynamic>> obtenerEstadoPago(int asesoradoId) async {
    final datos = await _obtenerDatosAsesorado(asesoradoId);

    if (datos == null) {
      return {
        'estado': 'activo',
        'saldo_pendiente': 0.0,
        'fecha_vencimiento': null,
        'total_pagado': 0.0,
        'costo_plan': 0.0,
        'plan_nombre': null,
        'periodo_a_pagar': null,
        'total_abonado_periodo': 0.0,
      };
    }

    final status = datos['status']?.toString() ?? 'activo';
    final costoPlan = _toDouble(datos['plan_costo']);
    final fechaVencimiento = _parseFecha(datos['fecha_vencimiento']);
    final planNombre = datos['plan_nombre']?.toString();

    if (costoPlan <= 0) {
      return {
        'estado': status,
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

    String estadoCalculado = status;
    if (status != 'enPausa') {
      if (periodoObjetivo.saldoPendiente > 0) {
        if (fechaVencimiento != null &&
            fechaVencimiento.isBefore(DateTime.now())) {
          estadoCalculado = 'deudor';
        } else if (fechaVencimiento != null &&
            fechaVencimiento.difference(DateTime.now()).inDays <= 7) {
          estadoCalculado = 'proximo';
        } else {
          estadoCalculado = 'pendiente';
        }
      } else {
        estadoCalculado = 'activa';
      }
    }

    return {
      'estado': estadoCalculado,
      'estado_original': status,
      'saldo_pendiente': periodoObjetivo.saldoPendiente,
      'fecha_vencimiento': fechaVencimiento,
      'total_pagado': periodoObjetivo.totalAbonado,
      'costo_plan': costoPlan,
      'plan_nombre': planNombre,
      'periodo_a_pagar': periodoObjetivo.periodo,
      'total_abonado_periodo': periodoObjetivo.totalAbonado,
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
  Future<List<String>> obtenerPeriodosPendientes(int asesoradoId) async {
    final results = await _db.query(
      '''
      SELECT p.periodo
      FROM pagos_membresias p
      INNER JOIN asesorados a ON p.asesorado_id = a.id
      LEFT JOIN planes pl ON a.plan_id = pl.id
      WHERE p.asesorado_id = ?
      GROUP BY p.periodo, pl.costo
      HAVING pl.costo IS NOT NULL AND COALESCE(SUM(p.monto), 0) < pl.costo
      ORDER BY p.periodo DESC
      ''',
      [asesoradoId],
    );
    return results.map((r) => r.fields['periodo'].toString()).toList();
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

  /// Obtiene asesorados con pagos pendientes para un coach con caché
  Future<List<AsesoradoPagoPendiente>> obtenerAsesoradosConPagosPendientes(
    int coachId, {
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      final cacheKey = 'pagos_pendientes_${coachId}_${page}_$pageSize';
      if (_isCacheValid(cacheKey)) {
        developer.log(
          '[CACHÉ HIT] Pagos pendientes para coach $coachId (desde caché)',
          name: 'PagosService',
        );
        return _cache[cacheKey]!.data;
      }

      developer.log(
        '[CACHÉ MISS] Obteniendo pagos pendientes para coach $coachId de BD',
        name: 'PagosService',
      );

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
        WHERE a.coach_id = ?
          AND a.plan_id IS NOT NULL
          AND (
            a.status = 'deudor' OR 
            (a.status = 'activo' AND a.fecha_vencimiento BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY))
          )
        ORDER BY a.fecha_vencimiento ASC
        LIMIT ? OFFSET ?
        ''',
        [coachId, pageSize, offset],
      );

      final resultado = [
        for (final row in results) AsesoradoPagoPendiente.fromMap(row.fields),
      ];

      _cache[cacheKey] = _CacheEntry(resultado);
      return resultado;
    } catch (e) {
      throw Exception('Error al obtener asesorados con pagos pendientes: $e');
    }
  }

  /// Obtiene asesorados con pagos atrasados (vencidos) para un coach
  Future<List<AsesoradoPagoPendiente>> obtenerAsesoradosConPagosAtrasados(
    int coachId,
  ) async {
    try {
      final cacheKey = 'pagos_atrasados_$coachId';
      if (_isCacheValid(cacheKey)) {
        developer.log(
          '[CACHÉ HIT] Pagos atrasados para coach $coachId',
          name: 'PagosService',
        );
        return _cache[cacheKey]!.data;
      }

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
          'atrasado' as estado
        FROM asesorados a
        LEFT JOIN planes p ON a.plan_id = p.id
        WHERE a.coach_id = ?
          AND a.status = 'deudor'
        ORDER BY a.fecha_vencimiento ASC
        ''',
        [coachId],
      );

      final resultado = [
        for (final row in results) AsesoradoPagoPendiente.fromMap(row.fields),
      ];

      _cache[cacheKey] = _CacheEntry(resultado);
      return resultado;
    } catch (e) {
      throw Exception('Error al obtener asesorados con pagos atrasados: $e');
    }
  }

  /// Obtiene asesorados con pagos próximos (en los próximos 7 días) para un coach
  Future<List<AsesoradoPagoPendiente>> obtenerAsesoradosConPagosProximos(
    int coachId,
  ) async {
    try {
      final cacheKey = 'pagos_proximos_$coachId';
      if (_isCacheValid(cacheKey)) {
        developer.log(
          '[CACHÉ HIT] Pagos próximos para coach $coachId',
          name: 'PagosService',
        );
        return _cache[cacheKey]!.data;
      }

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
          'proximo' as estado
        FROM asesorados a
        LEFT JOIN planes p ON a.plan_id = p.id
        WHERE a.coach_id = ?
          AND a.plan_id IS NOT NULL
          AND a.status = 'activo'
          AND a.fecha_vencimiento BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)
        ORDER BY a.fecha_vencimiento ASC
        ''',
        [coachId],
      );

      final resultado = [
        for (final row in results) AsesoradoPagoPendiente.fromMap(row.fields),
      ];

      _cache[cacheKey] = _CacheEntry(resultado);
      return resultado;
    } catch (e) {
      throw Exception('Error al obtener asesorados con pagos próximos: $e');
    }
  }

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

  /// Invalida el caché para un coach específico
  void invalidarCacheCoach(int coachId) {
    _cache.removeWhere((key, _) => key.startsWith('pagos_pendientes_$coachId'));
    _cache.remove('pagos_atrasados_$coachId');
    _cache.remove('pagos_proximos_$coachId');
    developer.log('Caché invalidado para coach $coachId', name: 'PagosService');
  }

  /// Limpia completamente el caché
  void limpiarCache() {
    _cache.clear();
    developer.log('Caché completamente limpiado', name: 'PagosService');
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

    String? periodoPendiente;
    double totalAbonado = 0.0;

    for (final row in resultados) {
      final periodo = row.fields['periodo']?.toString();
      if (periodo == null || periodo.isEmpty) {
        continue;
      }

      final total = _toDouble(row.fields['total_pagado']);

      if (costoPlan > 0 && total + 0.01 < costoPlan) {
        periodoPendiente = periodo;
        totalAbonado = total;
        break;
      }
    }

    if (periodoPendiente == null) {
      String? ultimoPeriodo;
      if (resultados.isNotEmpty) {
        ultimoPeriodo = resultados.last.fields['periodo']?.toString();
      }

      if (ultimoPeriodo != null && ultimoPeriodo.isNotEmpty) {
        final base = _parsePeriodo(ultimoPeriodo);
        periodoPendiente = _formatPeriodo(_sumarMeses(base, 1));
      } else if (fechaVencimiento != null) {
        final base = DateTime(fechaVencimiento.year, fechaVencimiento.month, 1);
        periodoPendiente = _formatPeriodo(base);
      } else {
        final now = DateTime.now();
        periodoPendiente = _formatPeriodo(DateTime(now.year, now.month, 1));
      }

      totalAbonado = 0.0;
    }

    final saldo =
        costoPlan <= 0 ? 0.0 : (costoPlan - totalAbonado).clamp(0.0, costoPlan);

    return _PeriodoObjetivo(
      periodo: periodoPendiente,
      totalAbonado: totalAbonado,
      saldoPendiente: saldo,
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

  Future<void> _extenderMembresia(int asesoradoId) async {
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

      // 3. Invalidar caché del coach si fue encontrado
      if (coachId != null) {
        invalidarCacheCoach(coachId);

        if (kDebugMode) {
          debugPrint(
            '[PagosService] ✅ Membresía extendida para asesorado $asesoradoId. '
            'Status: activo | Fecha vencimiento: +30 días. Coach $coachId caché invalidado.',
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

  /// 🎯 TAREA 1.3: Verifica si los abonos completan el plan y aplica cambios de estado
  /// Retorna true si el estado cambió y membresía fue extendida
  Future<bool> verificarYAplicarEstadoAbono({
    required int asesoradoId,
    required String periodo,
  }) async {
    try {
      // 1. Obtener el plan actual y costo del asesorado
      final asesoradoResult = await _db.query(
        'SELECT plan_actual, costo_plan, coach_id FROM asesorados WHERE id = ?',
        [asesoradoId],
      );

      if (asesoradoResult.isEmpty) {
        if (kDebugMode) {
          debugPrint('[PagosService] Asesorado $asesoradoId no encontrado');
        }
        return false;
      }

      final costoPlan = _toDouble(asesoradoResult.first['costo_plan']);

      // 2. Sumar abonos del período (tipo = 'abono')
      final abonoResult = await _db.query(
        '''
        SELECT COALESCE(SUM(monto), 0) as total_abonos
        FROM pagos_membresias
        WHERE asesorado_id = ? AND periodo = ? AND tipo = 'abono'
        ''',
        [asesoradoId, periodo],
      );

      final totalAbonos = _toDouble(abonoResult.first['total_abonos']);

      if (kDebugMode) {
        debugPrint(
          '[PagosService] Verificación abonos - Asesorado: $asesoradoId, '
          'Período: $periodo, Total abonos: \$${totalAbonos.toStringAsFixed(2)}, '
          'Costo plan: \$${costoPlan.toStringAsFixed(2)}',
        );
      }

      // 3. Verificar si abono >= costo del plan
      if (totalAbonos >= costoPlan) {
        // 4. Cambiar estado a 'activo'
        await _db.query(
          "UPDATE asesorados SET status = 'activo' WHERE id = ?",
          [asesoradoId],
        );

        if (kDebugMode) {
          debugPrint(
            '[PagosService] ✅ Estado asesorado $asesoradoId cambió a ACTIVO '
            '(abonos completan plan)',
          );
        }

        // 5. Extender membresía (+30 días)
        await _extenderMembresia(asesoradoId);

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

  const _PeriodoObjetivo({
    required this.periodo,
    required this.totalAbonado,
    required this.saldoPendiente,
  });
}

/// Entrada en el caché con timestamp para validación de expiración
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  _CacheEntry(this.data) : timestamp = DateTime.now();
}
