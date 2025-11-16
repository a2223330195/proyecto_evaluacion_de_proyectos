import 'package:coachhub/services/db_connection.dart';

/// Servicio de optimización de queries a la base de datos
/// Reduce N+1 queries y optimiza JOINs
class QueryOptimizationService {
  static final QueryOptimizationService _instance =
      QueryOptimizationService._internal();

  factory QueryOptimizationService() {
    return _instance;
  }

  QueryOptimizationService._internal();

  final DatabaseConnection _db = DatabaseConnection.instance;

  /// Carga asesorados con datos relacionados en una sola query
  /// Evita N+1 queries problem
  Future<List<Map<String, dynamic>>> loadAsesoradosWithDetails({
    String? searchQuery,
    String? statusFilter,
  }) async {
    String whereClause = '';
    List<Object?> params = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause += 'a.nombre LIKE ?';
      params.add('%$searchQuery%');
    }

    if (statusFilter != null && statusFilter.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'a.status = ?';
      params.add(statusFilter);
    }

    // Query optimizada con JOIN single para datos relacionados
    final sql = '''
      SELECT 
        a.id, a.nombre, a.avatar_url, a.status, a.plan_id,
        a.fecha_vencimiento, a.fecha_nacimiento, a.sexo, a.altura_cm, a.telefono,
        a.fecha_inicio_programa, a.objetivo_principal, a.objetivo_secundario,
        p.nombre AS plan_nombre, p.costo AS plan_costo,
        COUNT(DISTINCT m.id) AS total_mediciones,
        COUNT(DISTINCT ag.id) AS total_asignaciones
      FROM asesorados a
      LEFT JOIN planes p ON a.plan_id = p.id
      LEFT JOIN mediciones m ON a.id = m.asesorado_id
      LEFT JOIN asignaciones_agenda ag ON a.id = ag.asesorado_id
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      GROUP BY a.id
      ORDER BY a.nombre
    ''';

    final results =
        params.isNotEmpty ? await _db.query(sql, params) : await _db.query(sql);

    return results.map((row) => row.fields).toList();
  }

  /// Carga agendas del mes con datos optimizados
  /// Evita múltiples queries para cada asignación
  Future<List<Map<String, dynamic>>> loadAgendaDelMes(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final sql = '''
      SELECT
        ag.id, ag.asesorado_id, ag.plantilla_id, ag.fecha_asignada,
        ag.hora_asignada, ag.status,
        a.nombre AS asesorado_nombre, a.avatar_url AS asesorado_avatar_url,
        r.nombre AS rutina_nombre, r.descripcion AS rutina_descripcion
      FROM asignaciones_agenda ag
      JOIN asesorados a ON ag.asesorado_id = a.id
      JOIN rutinas_plantillas r ON ag.plantilla_id = r.id
      WHERE ag.fecha_asignada BETWEEN ? AND ?
      ORDER BY ag.fecha_asignada ASC, ag.hora_asignada ASC
    ''';

    final results = await _db.query(sql, [
      startDate.toString().split(' ')[0],
      endDate.toString().split(' ')[0],
    ]);

    return results.map((row) => row.fields).toList();
  }

  /// Carga rutinas con cantidad de asesorados asignados
  /// Evita queries adicionales por rutina
  Future<List<Map<String, dynamic>>> loadRutinasWithStats({
    String? searchQuery,
    String? categoryFilter,
  }) async {
    String whereClause = '';
    List<Object?> params = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause += 'r.nombre LIKE ?';
      params.add('%$searchQuery%');
    }

    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'r.categoria = ?';
      params.add(categoryFilter);
    }

    final sql = '''
      SELECT
        r.id, r.nombre, r.descripcion, r.categoria,
        COUNT(ag.id) AS total_asignaciones,
        COUNT(DISTINCT ag.asesorado_id) AS unique_asesorados
      FROM rutinas_plantillas r
      LEFT JOIN asignaciones_agenda ag ON r.id = ag.plantilla_id
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      GROUP BY r.id
      ORDER BY r.nombre
    ''';

    final results =
        params.isNotEmpty ? await _db.query(sql, params) : await _db.query(sql);

    return results.map((row) => row.fields).toList();
  }

  /// Carga información de pagos con datos de asesorados
  Future<List<Map<String, dynamic>>> loadPagosWithDetails({
    int? asesoradoId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String whereClause = '';
    List<Object?> params = [];

    if (asesoradoId != null) {
      whereClause += 'pm.asesorado_id = ?';
      params.add(asesoradoId);
    }

    if (startDate != null && endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'pm.fecha_pago BETWEEN ? AND ?';
      params.add(startDate.toString().split(' ')[0]);
      params.add(endDate.toString().split(' ')[0]);
    }

    final sql = '''
      SELECT
        pm.id, pm.asesorado_id, pm.fecha_pago, pm.monto,
        pm.created_at,
        a.nombre AS asesorado_nombre,
        SUM(pm.monto) OVER (PARTITION BY pm.asesorado_id ORDER BY pm.fecha_pago) AS running_total
      FROM pagos_membresias pm
      JOIN asesorados a ON pm.asesorado_id = a.id
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      ORDER BY pm.fecha_pago DESC
    ''';

    final results =
        params.isNotEmpty ? await _db.query(sql, params) : await _db.query(sql);

    return results.map((row) => row.fields).toList();
  }

  /// Carga mediciones de asesorado con historial
  /// Optimizado con índice compuesto
  Future<List<Map<String, dynamic>>> loadMedicionesWithHistory(
    int asesoradoId, {
    int limit = 10,
  }) async {
    final sql = '''
      SELECT
        m.id, m.asesorado_id, m.fecha_medicion,
        m.peso, m.porcentaje_grasa, m.imc, m.masa_muscular,
        m.agua_corporal, m.circunferencia_cintura,
        LAG(m.peso) OVER (ORDER BY m.fecha_medicion DESC) AS peso_anterior,
        LAG(m.imc) OVER (ORDER BY m.fecha_medicion DESC) AS imc_anterior,
        (m.peso - LAG(m.peso) OVER (ORDER BY m.fecha_medicion DESC)) AS peso_cambio
      FROM mediciones m
      WHERE m.asesorado_id = ?
      ORDER BY m.fecha_medicion DESC
      LIMIT ?
    ''';

    final results = await _db.query(sql, [asesoradoId, limit]);

    return results.map((row) => row.fields).toList();
  }

  /// Obtiene estadísticas generales del coach
  /// Single query para múltiples stats
  Future<Map<String, dynamic>> getCoachDashboardStats(int coachId) async {
    final sql = '''
      SELECT
        COUNT(DISTINCT a.id) AS total_asesorados,
        COUNT(DISTINCT CASE WHEN a.status = 'activo' THEN a.id END) AS asesorados_activos,
        COUNT(DISTINCT CASE WHEN a.status = 'deudor' THEN a.id END) AS asesorados_deudores,
        SUM(pm.monto) AS ingresos_activos,
        COUNT(DISTINCT CASE WHEN ag.status = 'pendiente' THEN ag.id END) AS actividades_pendientes,
        COUNT(DISTINCT ag.id) AS total_actividades_mes
      FROM asesorados a
      LEFT JOIN pagos_membresias pm ON a.id = pm.asesorado_id AND MONTH(pm.fecha_pago) = MONTH(NOW())
      LEFT JOIN asignaciones_agenda ag ON a.id = ag.asesorado_id AND MONTH(ag.fecha_asignada) = MONTH(NOW())
      WHERE a.plan_id IN (SELECT id FROM planes WHERE coach_id = ?)
    ''';

    final results = await _db.query(sql, [coachId]);

    if (results.isNotEmpty) {
      return results.first.fields;
    }

    return {};
  }

  /// Carga notas de seguimiento con estadísticas
  Future<List<Map<String, dynamic>>> loadNotasWithStats(int asesoradoId) async {
    final sql = '''
      SELECT
        n.id,
        n.asesorado_id,
        n.contenido AS nota,
        n.prioritaria AS es_prioritaria,
        n.fecha_creacion AS created_at,
        n.fecha_actualizacion,
        COUNT(*) OVER (PARTITION BY n.asesorado_id) AS total_notas
      FROM notas n
      WHERE n.asesorado_id = ?
      ORDER BY n.prioritaria DESC, n.fecha_creacion DESC
    ''';

    final results = await _db.query(sql, [asesoradoId]);

    return results.map((row) => row.fields).toList();
  }
}
