import 'dart:developer' as developer;

import 'package:coachhub/models/asesorado_pago_pendiente.dart';
import 'package:coachhub/services/db_connection.dart';

/// Servicio para obtener asesorados con pagos pendientes CON CACHÉ
///
/// REFACTORIZADO (TANDA 2):
/// ✓ Usa la tabla `asesorados` como fuente única de verdad.
/// ✓ Simplifica consultas según estado y fecha de vencimiento.
class PagosPendientesService {
  final DatabaseConnection _db;

  final Map<String, CacheEntry<List<AsesoradoPagoPendiente>>> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  PagosPendientesService(this._db);

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
          name: 'PagosPendientesService',
        );
        return _cache[cacheKey]!.data;
      }

      developer.log(
        '[CACHÉ MISS] Obteniendo pagos pendientes para coach $coachId de BD',
        name: 'PagosPendientesService',
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

      _cache[cacheKey] = CacheEntry(resultado);
      return resultado;
    } catch (e) {
      throw Exception('Error al obtener asesorados con pagos pendientes: $e');
    }
  }

  Future<List<AsesoradoPagoPendiente>> obtenerAsesoradosConPagosAtrasados(
    int coachId,
  ) async {
    try {
      final cacheKey = 'pagos_atrasados_$coachId';
      if (_isCacheValid(cacheKey)) {
        developer.log(
          '[CACHÉ HIT] Pagos atrasados para coach $coachId',
          name: 'PagosPendientesService',
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

      _cache[cacheKey] = CacheEntry(resultado);
      return resultado;
    } catch (e) {
      throw Exception('Error al obtener asesorados con pagos atrasados: $e');
    }
  }

  Future<List<AsesoradoPagoPendiente>> obtenerAsesoradosConPagosProximos(
    int coachId,
  ) async {
    try {
      final cacheKey = 'pagos_proximos_$coachId';
      if (_isCacheValid(cacheKey)) {
        developer.log(
          '[CACHÉ HIT] Pagos próximos para coach $coachId',
          name: 'PagosPendientesService',
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

      _cache[cacheKey] = CacheEntry(resultado);
      return resultado;
    } catch (e) {
      throw Exception('Error al obtener asesorados con pagos próximos: $e');
    }
  }

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

  void invalidarCacheCoach(int coachId) {
    _cache.removeWhere((key, _) => key.startsWith('pagos_pendientes_$coachId'));
    _cache.remove('pagos_atrasados_$coachId');
    _cache.remove('pagos_proximos_$coachId');
    developer.log(
      'Caché invalidado para coach $coachId',
      name: 'PagosPendientesService',
    );
  }

  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;
    final entry = _cache[key]!;
    return DateTime.now().difference(entry.timestamp) < _cacheDuration;
  }

  void limpiarCache() {
    _cache.clear();
    developer.log(
      'Caché completamente limpiado',
      name: 'PagosPendientesService',
    );
  }
}

class CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  CacheEntry(this.data) : timestamp = DateTime.now();
}
