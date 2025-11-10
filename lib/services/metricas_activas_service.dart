// lib/services/metricas_activas_service.dart

import 'package:coachhub/models/asesorado_metricas_activas_model.dart';
import 'package:coachhub/utils/app_error_handler.dart' show executeWithRetry;
import 'db_connection.dart';

class MetricasActivasService {
  // 🛡️ MÓDULO 4: Cache mejorado para fallback offline
  // ignore: unused_field
  final Map<int, AsesoradoMetricasActivas> _metricasCache = {};
  // ignore: unused_field
  final Map<int, DateTime> _metricasCacheTime = {};
  // ignore: unused_field
  static const Duration _cacheDuration = Duration(minutes: 10);

  /// Obtener configuración de métricas activas para un asesorado
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<AsesoradoMetricasActivas> getMetricasActivas(int asesoradoId) async {
    return executeWithRetry(() async {
      final db = DatabaseConnection.instance;

      try {
        final results = await db.query(
          'SELECT * FROM asesorado_metricas_activas WHERE asesorado_id = ?',
          [asesoradoId],
        );

        AsesoradoMetricasActivas metricas;
        if (results.isEmpty) {
          // Crear registro por defecto
          await _crearRegistroDefault(asesoradoId);
          metricas = AsesoradoMetricasActivas.defaults(asesoradoId);
        } else {
          final row = results.first.fields;
          metricas = AsesoradoMetricasActivas.fromMap(
            Map<String, dynamic>.from(row),
          );
        }

        // Guardar en caché
        _metricasCache[asesoradoId] = metricas;
        _metricasCacheTime[asesoradoId] = DateTime.now();
        return metricas;
      } catch (e) {
        // Retornar defaults en caso de error
        return AsesoradoMetricasActivas.defaults(asesoradoId);
      }
    }, operationName: 'getMetricasActivas($asesoradoId)');
  }

  /// Guardar/actualizar métricas activas para un asesorado
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<bool> saveMetricasActivas(
    int asesoradoId,
    Map<MetricaKey, bool> metricas,
  ) async {
    return executeWithRetry(() async {
      final db = DatabaseConnection.instance;

      const sql = '''
          INSERT OR REPLACE INTO asesorado_metricas_activas (
            asesorado_id, 
            peso_activo, 
            imc_activo, 
            porcentaje_grasa_activo,
            masa_muscular_activo, 
            agua_corporal_activo, 
            pecho_cm_activo,
            cintura_cm_activo, 
            cadera_cm_activo, 
            brazo_izq_cm_activo,
            brazo_der_cm_activo, 
            pierna_izq_cm_activo, 
            pierna_der_cm_activo,
            pantorrilla_izq_cm_activo, 
            pantorrilla_der_cm_activo,
            frecuencia_cardiaca_activo, 
            record_resistencia_activo,
            updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''';

      await db.query(sql, [
        asesoradoId,
        (metricas[MetricaKey.peso] ?? false) ? 1 : 0,
        (metricas[MetricaKey.imc] ?? false) ? 1 : 0,
        (metricas[MetricaKey.porcentajeGrasa] ?? false) ? 1 : 0,
        (metricas[MetricaKey.masaMuscular] ?? false) ? 1 : 0,
        (metricas[MetricaKey.aguaCorporal] ?? false) ? 1 : 0,
        (metricas[MetricaKey.pechoCm] ?? false) ? 1 : 0,
        (metricas[MetricaKey.cinturaCm] ?? false) ? 1 : 0,
        (metricas[MetricaKey.caderaCm] ?? false) ? 1 : 0,
        (metricas[MetricaKey.brazoIzqCm] ?? false) ? 1 : 0,
        (metricas[MetricaKey.brazoDerCm] ?? false) ? 1 : 0,
        (metricas[MetricaKey.piernaIzqCm] ?? false) ? 1 : 0,
        (metricas[MetricaKey.piernaDerCm] ?? false) ? 1 : 0,
        (metricas[MetricaKey.pantorrillaIzqCm] ?? false) ? 1 : 0,
        (metricas[MetricaKey.pantorrillaDerCm] ?? false) ? 1 : 0,
        (metricas[MetricaKey.frecuenciaCardiaca] ?? false) ? 1 : 0,
        (metricas[MetricaKey.recordResistencia] ?? false) ? 1 : 0,
        DateTime.now().toIso8601String(),
      ]);

      return true;
    }, operationName: 'saveMetricasActivas($asesoradoId)');
  }

  /// Crear registro por defecto para un asesorado
  Future<void> _crearRegistroDefault(int asesoradoId) async {
    final db = DatabaseConnection.instance;

    const sql = '''
      INSERT INTO asesorado_metricas_activas (asesorado_id)
      VALUES (?)
    ''';

    try {
      await db.query(sql, [asesoradoId]);
    } catch (e) {
      // No lanzar excepción, permitir que la app continue
    }
  }

  /// Restablecer a valores por defecto
  Future<bool> resetMetricasActivas(int asesoradoId) async {
    final defaults = AsesoradoMetricasActivas.defaults(asesoradoId).metricas;
    return saveMetricasActivas(asesoradoId, defaults);
  }

  /// Activar solo una métrica (desactivas el resto)
  Future<bool> setOnlyMetrica(int asesoradoId, MetricaKey metrica) async {
    final metricas = <MetricaKey, bool>{};
    for (final key in MetricaKey.values) {
      metricas[key] = key == metrica;
    }
    return saveMetricasActivas(asesoradoId, metricas);
  }

  /// Activar múltiples métricas
  Future<bool> setMetricas(int asesoradoId, List<MetricaKey> activas) async {
    final metricas = <MetricaKey, bool>{};
    for (final key in MetricaKey.values) {
      metricas[key] = activas.contains(key);
    }
    return saveMetricasActivas(asesoradoId, metricas);
  }

  /// Activar todas las métricas
  Future<bool> activarTodas(int asesoradoId) async {
    final metricas = <MetricaKey, bool>{};
    for (final key in MetricaKey.values) {
      metricas[key] = true;
    }
    return saveMetricasActivas(asesoradoId, metricas);
  }

  /// Desactivar todas las métricas
  Future<bool> desactivarTodas(int asesoradoId) async {
    final metricas = <MetricaKey, bool>{};
    for (final key in MetricaKey.values) {
      metricas[key] = false;
    }
    return saveMetricasActivas(asesoradoId, metricas);
  }

  /// Alternar estado de una métrica
  Future<bool> toggleMetrica(int asesoradoId, MetricaKey metrica) async {
    try {
      final actual = await getMetricasActivas(asesoradoId);
      final nuevoEstado = !(actual.metricas[metrica] ?? false);
      final nuevasMetricas = Map<MetricaKey, bool>.from(actual.metricas);
      nuevasMetricas[metrica] = nuevoEstado;
      return saveMetricasActivas(asesoradoId, nuevasMetricas);
    } catch (e) {
      return false;
    }
  }
}
