import 'package:coachhub/models/asesorado_model.dart';
import 'package:coachhub/models/dashboard_models.dart';
import 'package:coachhub/services/db_connection.dart';
import 'package:intl/intl.dart';

/// Dashboard Service
/// Proporciona métodos para obtener datos del dashboard de forma centralizada
class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  final DatabaseConnection _db = DatabaseConnection.instance;

  DashboardService._internal();

  factory DashboardService() {
    return _instance;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is BigInt) return value.toInt();
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is BigInt) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  /// Obtiene el total de asesorados por estado
  Future<Map<String, int>> getAsesoradosStats(int coachId) async {
    final result = await _db.query(
      '''
        SELECT 
          COUNT(*) AS total,
          SUM(CASE WHEN status = 'activo' THEN 1 ELSE 0 END) AS activos,
          SUM(CASE WHEN status = 'deudor' THEN 1 ELSE 0 END) AS deudores,
          SUM(CASE WHEN status = 'enPausa' THEN 1 ELSE 0 END) AS enPausa
        FROM asesorados
        WHERE coach_id = ?
      ''',
      [coachId],
    );

    if (result.isEmpty) {
      return {'total': 0, 'activos': 0, 'deudores': 0, 'enPausa': 0};
    }

    final row = result.first;
    return {
      'total': _toInt(row['total']),
      'activos': _toInt(row['activos']),
      'deudores': _toInt(row['deudores']),
      'enPausa': _toInt(row['enPausa']),
    };
  }

  /// Calcula los ingresos mensuales proyectados
  Future<double> getIngresosMensuales(int coachId) async {
    final result = await _db.query(
      '''
        SELECT COALESCE(SUM(pm.monto), 0) AS total
        FROM pagos_membresias pm
        JOIN asesorados a ON pm.asesorado_id = a.id
        WHERE a.coach_id = ?
          AND MONTH(pm.fecha_pago) = MONTH(CURDATE())
          AND YEAR(pm.fecha_pago) = YEAR(CURDATE())
      ''',
      [coachId],
    );

    if (result.isEmpty) return 0.0;
    return _toDouble(result.first['total']);
  }

  /// Obtiene asesorados próximos a vencer (próximos 7 días)
  Future<List<Asesorado>> getAsesoradosProximosAVencer(int coachId) async {
    final result = await _db.query(
      '''
        SELECT *
        FROM asesorados 
        WHERE coach_id = ?
          AND fecha_vencimiento IS NOT NULL
          AND fecha_vencimiento <= DATE_ADD(CURDATE(), INTERVAL 7 DAY)
          AND status != 'enPausa'
        ORDER BY fecha_vencimiento ASC
        LIMIT 5
      ''',
      [coachId],
    );

    if (result.isEmpty) {
      return const [];
    }

    return result.map((row) => Asesorado.fromMap(row.fields)).toList();
  }

  /// Obtiene la agenda del día para la fecha proporcionada.
  Future<List<AgendaSession>> getAgendaForDate(
    DateTime date,
    int coachId,
  ) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    const sql = '''
      SELECT
        ag.id,
        ag.status,
        ag.hora_asignada,
        a.id AS asesorado_id,
        a.nombre AS asesorado_nombre,
        a.avatar_url AS asesorado_avatar_url,
        r.nombre AS rutina_nombre
      FROM asignaciones_agenda ag
      JOIN asesorados a ON ag.asesorado_id = a.id
      JOIN rutinas_plantillas r ON ag.plantilla_id = r.id
      WHERE ag.fecha_asignada = ?
        AND a.coach_id = ?
      ORDER BY ag.hora_asignada
    ''';

    final result = await _db.query(sql, [formattedDate, coachId]);
    if (result.isEmpty) {
      return const [];
    }

    return result
        .map(
          (row) => AgendaSession(
            id: _toInt(row['id']),
            status: row['status']?.toString() ?? 'pendiente',
            horaAsignada: row['hora_asignada']?.toString() ?? '--:--',
            asesoradoId: _toInt(row['asesorado_id']),
            asesoradoNombre: row['asesorado_nombre']?.toString() ?? 'N/A',
            asesoradoAvatarUrl: row['asesorado_avatar_url']?.toString() ?? '',
            rutinaNombre: row['rutina_nombre']?.toString() ?? 'N/A',
          ),
        )
        .toList();
  }

  /// Devuelve la actividad reciente (máximo [limit] entradas).
  Future<List<DashboardActivity>> getRecentActivity(
    int coachId, {
    int limit = 5,
  }) async {
    final result = await _db.query(
      '''
      SELECT 
        a.nombre AS asesorado_nombre,
        r.nombre AS rutina_nombre,
        ag.created_at
      FROM asignaciones_agenda ag
      JOIN asesorados a ON ag.asesorado_id = a.id
      JOIN rutinas_plantillas r ON ag.plantilla_id = r.id
      WHERE a.coach_id = ?
        AND ag.status = 'completada'
      ORDER BY ag.created_at DESC
      LIMIT ?
    ''',
      [coachId, limit],
    );

    if (result.isEmpty) {
      return const [];
    }

    return result
        .map(
          (row) => DashboardActivity(
            asesoradoNombre: row['asesorado_nombre']?.toString() ?? 'N/A',
            rutinaNombre: row['rutina_nombre']?.toString() ?? 'N/A',
            timestamp:
                row['created_at'] != null
                    ? DateTime.tryParse(row['created_at'].toString()) ??
                        DateTime.now()
                    : DateTime.now(),
          ),
        )
        .toList();
  }

  /// Obtiene la lista de asesorados con pagos vencidos.
  Future<List<Asesorado>> getDeudores(int coachId, {int limit = 5}) async {
    final result = await _db.query(
      '''
        SELECT *
        FROM asesorados
        WHERE coach_id = ?
          AND status = 'deudor'
        ORDER BY fecha_vencimiento ASC
        LIMIT ?
      ''',
      [coachId, limit],
    );

    if (result.isEmpty) {
      return const [];
    }

    return result.map((row) => Asesorado.fromMap(row.fields)).toList();
  }

  /// Obtiene las métricas semanales del dashboard para la semana dada.
  /// [weekOffset] permite navegar semanas anteriores o siguientes respecto a la actual.
  Future<WeeklySummary> getWeeklySummary({
    required int coachId,
    int weekOffset = 0,
    int? asesoradosActivos,
  }) async {
    final referenceDate = DateTime.now().add(Duration(days: 7 * weekOffset));
    final startOfWeekRaw = referenceDate.subtract(
      Duration(days: referenceDate.weekday - 1),
    );
    final endOfWeekRaw = startOfWeekRaw.add(const Duration(days: 6));
    final startOfWeek = DateTime(
      startOfWeekRaw.year,
      startOfWeekRaw.month,
      startOfWeekRaw.day,
    );
    final endOfWeek = DateTime(
      endOfWeekRaw.year,
      endOfWeekRaw.month,
      endOfWeekRaw.day,
    );

    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final startBound = dateFormatter.format(startOfWeek);
    final endBound = dateFormatter.format(
      endOfWeek.add(const Duration(hours: 23, minutes: 59, seconds: 59)),
    );

    dynamic weeklyResult;
    try {
      weeklyResult = await _db.query(
        '''
          SELECT 
            COUNT(*) AS total,
            SUM(CASE WHEN ag.status = 'completada' THEN 1 ELSE 0 END) AS completadas
          FROM asignaciones_agenda ag
          JOIN asesorados a ON ag.asesorado_id = a.id
          WHERE a.coach_id = ?
            AND ag.fecha_asignada BETWEEN ? AND ?
        ''',
        [coachId, startBound, endBound],
      );
    } catch (_) {
      weeklyResult = [];
    }

    final sesionesTotales =
        weeklyResult is List && weeklyResult.isNotEmpty
            ? _toInt(weeklyResult.first['total'])
            : 0;
    final sesionesCompletadas =
        weeklyResult is List && weeklyResult.isNotEmpty
            ? _toInt(weeklyResult.first['completadas'])
            : 0;

    dynamic asistenciaResult;
    try {
      asistenciaResult = await _db.query(
        '''
          SELECT 
            COUNT(*) AS total,
            SUM(CASE WHEN ag.status = 'completada' THEN 1 ELSE 0 END) AS completadas
          FROM asignaciones_agenda ag
          JOIN asesorados a ON ag.asesorado_id = a.id
          WHERE a.coach_id = ?
        ''',
        [coachId],
      );
    } catch (_) {
      asistenciaResult = [];
    }

    final asistenciaTotal =
        asistenciaResult is List && asistenciaResult.isNotEmpty
            ? _toInt(asistenciaResult.first['total'])
            : 0;
    final asistenciaCompletada =
        asistenciaResult is List && asistenciaResult.isNotEmpty
            ? _toInt(asistenciaResult.first['completadas'])
            : 0;

    final porcentajeCompletado =
        sesionesTotales > 0
            ? (sesionesCompletadas / sesionesTotales * 100)
            : 0.0;
    final porcentajeAsistencia =
        asistenciaTotal > 0
            ? (asistenciaCompletada / asistenciaTotal * 100)
            : 0.0;

    return WeeklySummary(
      asesoradosActivos: asesoradosActivos ?? 0,
      sesionesCompletadas: sesionesCompletadas,
      sesionesTotales: sesionesTotales,
      porcentajeCompletado: porcentajeCompletado,
      porcentajeAsistencia: porcentajeAsistencia,
    );
  }

  /// Actualiza el estado de asesorados a 'deudor' cuando la fecha de vencimiento expiró.
  Future<void> updateDeudores(int coachId) async {
    try {
      await _db.query(
        '''
        UPDATE asesorados 
        SET status = 'deudor' 
        WHERE coach_id = ?
          AND fecha_vencimiento < CURDATE() 
          AND status = 'activo'
        ''',
        [coachId],
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el total de deudores actuales
  Future<int> getDeudoresCount(int coachId) async {
    try {
      final result = await _db.query(
        'SELECT COUNT(*) as total FROM asesorados WHERE coach_id = ? AND status = ?',
        [coachId, 'deudor'],
      );

      if (result.isEmpty) return 0;
      return (result.first['total'] as int?) ?? 0;
    } catch (e) {
      rethrow;
    }
  }

  /// Marca una sesión agendada como completada y actualiza en la base de datos
  Future<void> markSessionAsCompleted(int asignacionId) async {
    try {
      await _db.query(
        'UPDATE asignaciones_agenda SET status = ? WHERE id = ?',
        ['completada', asignacionId],
      );
    } catch (e) {
      rethrow;
    }
  }
}
