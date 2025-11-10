import 'package:coachhub/services/db_connection.dart';
import 'package:coachhub/models/plan_nutricional_model.dart';
import 'package:coachhub/utils/app_error_handler.dart' show executeWithRetry;

class PlanesService {
  final _db = DatabaseConnection.instance;

  // 🛡️ MÓDULO 4: Cache mejorado para fallback offline
  // ignore: unused_field
  final Map<int, List<PlanNutricional>> _planesCache = {};
  // ignore: unused_field
  final Map<int, DateTime> _planesCacheTime = {};
  // ignore: unused_field
  static const Duration _cacheDuration = Duration(minutes: 10);

  /// Obtener planes por asesorado
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<List<PlanNutricional>> getPlanesByAsesorado(int asesoradoId) async {
    return executeWithRetry(() async {
      final results = await _db.query(
        'SELECT * FROM planes_nutricionales WHERE asesorado_id = ? ORDER BY created_at DESC',
        [asesoradoId],
      );
      final planes =
          results.map((r) => PlanNutricional.fromMap(r.fields)).toList();
      _planesCache[asesoradoId] = planes;
      _planesCacheTime[asesoradoId] = DateTime.now();
      return planes;
    }, operationName: 'getPlanesByAsesorado($asesoradoId)');
  }

  /// Crear plan
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<void> createPlan(PlanNutricional plan) async {
    return executeWithRetry(
      () => _db.query(
        'INSERT INTO planes_nutricionales (asesorado_id, nombre_plan, calorias_diarias, proteinas_gr, grasas_gr, carbos_gr, recomendaciones) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          plan.asesoradoId,
          plan.nombrePlan,
          plan.caloriasDiarias,
          plan.proteinasGr,
          plan.grasasGr,
          plan.carbosGr,
          plan.recomendaciones,
        ],
      ),
      operationName: 'createPlan',
    );
  }

  /// Actualizar plan
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<void> updatePlan(PlanNutricional plan) async {
    return executeWithRetry(
      () => _db.query(
        'UPDATE planes_nutricionales SET nombre_plan = ?, calorias_diarias = ?, proteinas_gr = ?, grasas_gr = ?, carbos_gr = ?, recomendaciones = ? WHERE id = ?',
        [
          plan.nombrePlan,
          plan.caloriasDiarias,
          plan.proteinasGr,
          plan.grasasGr,
          plan.carbosGr,
          plan.recomendaciones,
          plan.id,
        ],
      ),
      operationName: 'updatePlan(${plan.id})',
    );
  }

  /// Eliminar plan
  /// 🛡️ MÓDULO 4: Con retry logic automático
  Future<void> deletePlan(int planId) async {
    return executeWithRetry(
      () =>
          _db.query('DELETE FROM planes_nutricionales WHERE id = ?', [planId]),
      operationName: 'deletePlan($planId)',
    );
  }
}
