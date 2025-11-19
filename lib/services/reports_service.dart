import 'dart:developer' as developer;
import 'dart:async';
import 'package:coachhub/models/report_models.dart';
import 'package:coachhub/services/db_connection.dart';

class _CachedReport {
  final dynamic data;
  final DateTime timestamp;

  _CachedReport({required this.data, required this.timestamp});
}

class _RoutineAssignmentRecord {
  final int assignmentId;
  final int routineId;
  final String routineName;
  final String routineCategory;
  final int asesoradoId;
  final String asesoradoName;
  final String? avatarUrl;

  _RoutineAssignmentRecord({
    required this.assignmentId,
    required this.routineId,
    required this.routineName,
    required this.routineCategory,
    required this.asesoradoId,
    required this.asesoradoName,
    this.avatarUrl,
  });
}

class _RoutineCompletionRecord {
  final int loggedExercises;
  final int loggedSeries;

  _RoutineCompletionRecord({
    required this.loggedExercises,
    required this.loggedSeries,
  });
}

class _RoutineStatsAccumulator {
  final String routineName;
  final String category;
  final Set<int> assignedAsesorados = <int>{};
  int usageExercises = 0;

  _RoutineStatsAccumulator({required this.routineName, required this.category});
}

class _RoutineProgressAccumulator {
  final String asesoradoName;
  final String? avatarUrl;
  final String routineName;
  int seriesAssigned = 0;
  int seriesCompleted = 0;

  _RoutineProgressAccumulator({
    required this.asesoradoName,
    this.avatarUrl,
    required this.routineName,
  });
}

class ReportsService {
  final _db = DatabaseConnection.instance;

  static final _instance = ReportsService._internal();

  ReportsService._internal();

  factory ReportsService() {
    return _instance;
  }

  final Map<String, _CachedReport> _cache = {};
  static const Duration _cacheExpiration = Duration(minutes: 15);

  String _generateCacheKey(
    String reportType,
    int coachId,
    DateRange dateRange,
    int? asesoradoId,
  ) {
    return '$reportType:$coachId:${dateRange.startDate}:${dateRange.endDate}:$asesoradoId';
  }

  void _setCacheData(String key, dynamic data) {
    _cache[key] = _CachedReport(data: data, timestamp: DateTime.now());
  }

  dynamic _getCacheData(String key) {
    if (_cache.containsKey(key)) {
      final cached = _cache[key]!;
      if (DateTime.now().difference(cached.timestamp) < _cacheExpiration) {
        developer.log('Cache hit: $key', name: 'ReportsService');
        return cached.data;
      } else {
        _cache.remove(key);
      }
    }
    return null;
  }

  void clearCache() {
    _cache.clear();
    developer.log('Cache cleared', name: 'ReportsService');
  }

  void clearCacheForCoach(int coachId) {
    _cache.removeWhere((key, _) => key.contains(':$coachId:'));
    developer.log('Cache cleared for coach $coachId', name: 'ReportsService');
  }

  Future<PaymentReportData> generatePaymentReport({
    required int coachId,
    required DateRange dateRange,
    int? asesoradoId,
  }) async {
    try {
      final cacheKey = _generateCacheKey(
        'pagos',
        coachId,
        dateRange,
        asesoradoId,
      );
      final cachedData = _getCacheData(cacheKey);
      if (cachedData != null) {
        return cachedData as PaymentReportData;
      }

      developer.log(
        'Generando reporte de pagos para coach $coachId',
        name: 'ReportsService',
      );

      final paymentsQuery = '''
        SELECT 
          pm.id,
          pm.asesorado_id,
          a.nombre as asesorado_name,
          a.avatar_url,
          pm.fecha_pago,
          pm.monto,
          pm.periodo,
          pm.tipo
        FROM pagos_membresias pm
        JOIN asesorados a ON pm.asesorado_id = a.id
        WHERE a.coach_id = ?
          AND pm.fecha_pago BETWEEN ? AND ?
          ${asesoradoId != null ? 'AND pm.asesorado_id = ?' : ''}
        ORDER BY pm.fecha_pago DESC
      ''';

      final params = [
        coachId,
        dateRange.startDate.toIso8601String().split('T')[0],
        dateRange.endDate.toIso8601String().split('T')[0],
        if (asesoradoId != null) asesoradoId,
      ];

      final paymentResults = await _db.query(paymentsQuery, params);
      final payments =
          paymentResults
              .map(
                (r) => PaymentDetail(
                  id: int.tryParse(r.fields['id'].toString()) ?? 0,
                  asesoradoName: r.fields['asesorado_name']?.toString() ?? '',
                  avatarUrl: r.fields['avatar_url']?.toString(),
                  paymentDate: DateTime.parse(
                    r.fields['fecha_pago'].toString(),
                  ),
                  amount: double.tryParse(r.fields['monto'].toString()) ?? 0.0,
                  type: r.fields['tipo']?.toString() ?? 'completo',
                  period: r.fields['periodo']?.toString() ?? '',
                ),
              )
              .toList();

      double totalIncome = 0.0;
      double completePayments = 0.0;
      double partialPayments = 0.0;
      final monthlyIncome = <String, double>{};

      for (final payment in payments) {
        totalIncome += payment.amount;

        if (payment.type == 'completo') {
          completePayments += payment.amount;
        } else {
          partialPayments += payment.amount;
        }

        final monthKey = payment.period;
        monthlyIncome[monthKey] =
            (monthlyIncome[monthKey] ?? 0.0) + payment.amount;
      }

      developer.log(
        'Pagos obtenidos: ${payments.length}',
        name: 'ReportsService',
      );

      final debtorsData = await _getDebtors(coachId, dateRange, asesoradoId);

      developer.log(
        'Deudores generados: ${debtorsData.length}',
        name: 'ReportsService',
      );

      final result = PaymentReportData(
        totalIncome: totalIncome,
        completePayments: completePayments,
        partialPayments: partialPayments,
        debtorCount: debtorsData.length,
        monthlyIncome: monthlyIncome,
        debtors: debtorsData,
        payments: payments,
      );

      _setCacheData(cacheKey, result);
      return result;
    } catch (e, s) {
      developer.log(
        'Error al generar reporte de pagos: $e',
        name: 'ReportsService',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<List<DebtorDetail>> _getDebtors(
    int coachId,
    DateRange dateRange,
    int? asesoradoId,
  ) async {
    try {
      developer.log(
        'Iniciando consulta de deudores para coach $coachId',
        name: 'ReportsService',
      );

      // Optimized query: avoid correlated subqueries by pre-grouping payments
      // and joining them to avoid N+1 problem.
      // Consulta optimizada: evita subconsultas correlacionadas agrupando pagos
      // dentro del rango de fechas especificado y haciendo JOIN para evitar problema N+1.
      final query = '''
        SELECT 
          a.id,
          a.nombre,
          a.avatar_url,
          a.plan_id,
          a.fecha_vencimiento,
          COALESCE(p.costo, 0) as plan_costo,
          COALESCE(pagos.total_pagado, 0) as total_pagado,
          COALESCE(pagos.ultimo_pago, '') as ultimo_pago,
          GREATEST(
            COALESCE(p.costo, 0) - COALESCE(pagos.total_pagado, 0),
            0
          ) as deuda_actual
        FROM asesorados a
        LEFT JOIN planes p ON a.plan_id = p.id
        LEFT JOIN (
          SELECT
            pm.asesorado_id,
            SUM(pm.monto) AS total_pagado,
            MAX(pm.fecha_pago) AS ultimo_pago
          FROM pagos_membresias pm
          WHERE pm.fecha_pago BETWEEN ? AND ?
          GROUP BY pm.asesorado_id
        ) pagos ON pagos.asesorado_id = a.id
        WHERE a.coach_id = ?
          AND a.plan_id IS NOT NULL
          ${asesoradoId != null ? 'AND a.id = ?' : ''}
        HAVING deuda_actual > 0
          OR a.fecha_vencimiento < CURDATE()
        ORDER BY deuda_actual DESC
      ''';

      final params = [
        dateRange.startDate.toIso8601String().split('T')[0],
        dateRange.endDate.toIso8601String().split('T')[0],
        coachId,
        if (asesoradoId != null) asesoradoId,
      ];

      final startTime = DateTime.now();
      final results = await _db.query(query, params);
      final duration = DateTime.now().difference(startTime);

      developer.log(
        'Consulta de deudores completada en ${duration.inMilliseconds}ms, resultados: ${results.length}',
        name: 'ReportsService',
      );

      return results
          .map((r) {
            final lastPaymentStr = r.fields['ultimo_pago']?.toString();
            final lastPaymentDate =
                lastPaymentStr != null && lastPaymentStr.isNotEmpty
                    ? DateTime.parse(lastPaymentStr)
                    : DateTime(1970); // Fecha por defecto si nunca ha pagado

            return DebtorDetail(
              asesoradoId: int.tryParse(r.fields['id'].toString()) ?? 0,
              asesoradoName: r.fields['nombre']?.toString() ?? '',
              avatarUrl: r.fields['avatar_url']?.toString(),
              debtAmount:
                  double.tryParse(
                    r.fields['deuda_actual']?.toString() ?? '0',
                  ) ??
                  0.0,
              lastPaymentDate: lastPaymentDate,
            );
          })
          .where((d) => d.debtAmount > 0)
          .toList();
    } catch (e, s) {
      developer.log(
        'Error al obtener deudores: $e',
        name: 'ReportsService',
        error: e,
        stackTrace: s,
      );
      return [];
    }
  }

  Future<RoutineReportData> generateRoutineReport({
    required int coachId,
    required DateRange dateRange,
    int? asesoradoId,
  }) async {
    try {
      final cacheKey = _generateCacheKey(
        'rutinas',
        coachId,
        dateRange,
        asesoradoId,
      );
      final cachedData = _getCacheData(cacheKey);
      if (cachedData != null) {
        return cachedData as RoutineReportData;
      }

      developer.log(
        'Generando reporte de rutinas para coach $coachId',
        name: 'ReportsService',
      );

      final params = [
        coachId,
        dateRange.startDate.toIso8601String().split('T')[0],
        dateRange.endDate.toIso8601String().split('T')[0],
        if (asesoradoId != null) asesoradoId,
      ];

      final assignmentsQuery = '''
        SELECT 
          aa.id AS assignment_id,
          rp.id AS routine_id,
          rp.nombre AS routine_name,
          rp.categoria AS routine_category,
          aa.asesorado_id,
          a.nombre AS asesorado_name,
          a.avatar_url
        FROM asignaciones_agenda aa
        JOIN asesorados a ON aa.asesorado_id = a.id
        JOIN rutinas_plantillas rp ON aa.plantilla_id = rp.id
        WHERE a.coach_id = ?
          AND aa.fecha_asignada BETWEEN ? AND ?
          AND aa.status != 'cancelada'
          ${asesoradoId != null ? 'AND aa.asesorado_id = ?' : ''}
      ''';

      developer.log(
        'Ejecutando assignmentsQuery (rutinas) para coach $coachId',
        name: 'ReportsService',
      );
      final assignmentsResult = await _db
          .query(assignmentsQuery, params)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              developer.log(
                'Timeout en assignmentsQuery (8s) — devolviendo resultados vacíos',
                name: 'ReportsService',
              );
              throw TimeoutException('assignmentsQuery timed out');
            },
          );
      final assignments = <_RoutineAssignmentRecord>[];

      for (final row in assignmentsResult) {
        final assignmentId = int.tryParse(
          row.fields['assignment_id']?.toString() ?? '',
        );
        final routineId = int.tryParse(
          row.fields['routine_id']?.toString() ?? '',
        );
        final asesoradoId = int.tryParse(
          row.fields['asesorado_id']?.toString() ?? '',
        );

        if (assignmentId == null || routineId == null || asesoradoId == null) {
          continue;
        }

        assignments.add(
          _RoutineAssignmentRecord(
            assignmentId: assignmentId,
            routineId: routineId,
            routineName: row.fields['routine_name']?.toString() ?? '',
            routineCategory: row.fields['routine_category']?.toString() ?? '',
            asesoradoId: asesoradoId,
            asesoradoName: row.fields['asesorado_name']?.toString() ?? '',
            avatarUrl: row.fields['avatar_url']?.toString(),
          ),
        );
      }

      if (assignments.isEmpty) {
        final emptyResult = RoutineReportData(
          mostUsedRoutines: const [],
          exerciseCompletion: const {},
          adherenceByAsesorado: const {},
          routineProgress: const [],
        );
        _setCacheData(cacheKey, emptyResult);
        return emptyResult;
      }

      final completionsQuery = '''
        SELECT 
          aa.id AS assignment_id,
          COUNT(DISTINCT le.id) AS logged_exercises,
          COUNT(DISTINCT ls.id) AS logged_series
        FROM asignaciones_agenda aa
        JOIN asesorados a ON aa.asesorado_id = a.id
        LEFT JOIN log_ejercicios le ON aa.id = le.asignacion_id
        LEFT JOIN log_series ls ON le.id = ls.log_ejercicio_id
        WHERE a.coach_id = ?
          AND aa.fecha_asignada BETWEEN ? AND ?
          AND aa.status != 'cancelada'
          ${asesoradoId != null ? 'AND aa.asesorado_id = ?' : ''}
        GROUP BY aa.id
      ''';

      developer.log(
        'Ejecutando completionsQuery (rutinas) para coach $coachId',
        name: 'ReportsService',
      );
      final completionsResult = await _db
          .query(completionsQuery, params)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              developer.log(
                'Timeout en completionsQuery (8s) — devolviendo sin completions',
                name: 'ReportsService',
              );
              throw TimeoutException('completionsQuery timed out');
            },
          );
      final completionByAssignment = <int, _RoutineCompletionRecord>{};

      for (final row in completionsResult) {
        final assignmentId = int.tryParse(
          row.fields['assignment_id']?.toString() ?? '',
        );
        if (assignmentId == null) {
          continue;
        }

        final loggedExercises =
            int.tryParse(row.fields['logged_exercises']?.toString() ?? '0') ??
            0;
        final loggedSeries =
            int.tryParse(row.fields['logged_series']?.toString() ?? '0') ?? 0;

        completionByAssignment[assignmentId] = _RoutineCompletionRecord(
          loggedExercises: loggedExercises,
          loggedSeries: loggedSeries,
        );
      }

      final routineStats = <int, _RoutineStatsAccumulator>{};
      final progressAccumulator = <String, _RoutineProgressAccumulator>{};

      for (final record in assignments) {
        final completion = completionByAssignment[record.assignmentId];
        final loggedExercises = completion?.loggedExercises ?? 0;
        final loggedSeries = completion?.loggedSeries ?? 0;

        final stats = routineStats.putIfAbsent(
          record.routineId,
          () => _RoutineStatsAccumulator(
            routineName: record.routineName,
            category: record.routineCategory,
          ),
        );

        stats.assignedAsesorados.add(record.asesoradoId);
        stats.usageExercises += loggedExercises;

        final progressKey = '${record.asesoradoId}_${record.routineId}';
        final progress = progressAccumulator.putIfAbsent(
          progressKey,
          () => _RoutineProgressAccumulator(
            asesoradoName: record.asesoradoName,
            avatarUrl: record.avatarUrl,
            routineName: record.routineName,
          ),
        );

        progress.seriesAssigned += 1;
        progress.seriesCompleted += loggedSeries;
      }

      final sortedRoutines =
          routineStats.entries.map((entry) {
              final stats = entry.value;
              return RoutineUsage(
                routineId: entry.key,
                routineName: stats.routineName,
                category: stats.category,
                usageCount: stats.usageExercises,
                assignedCount: stats.assignedAsesorados.length,
              );
            }).toList()
            ..sort((a, b) {
              final usageCompare = b.usageCount.compareTo(a.usageCount);
              if (usageCompare != 0) {
                return usageCompare;
              }
              return b.assignedCount.compareTo(a.assignedCount);
            });

      final mostUsedRoutines = sortedRoutines.take(10).toList();

      final progressData =
          progressAccumulator.values.map((acc) {
              final assigned = acc.seriesAssigned;
              final completed = acc.seriesCompleted;
              final rawPercentage =
                  assigned == 0 ? 0.0 : (completed / assigned) * 100.0;
              final percentage = rawPercentage.clamp(0.0, 100.0).toDouble();

              return RoutineProgress(
                asesoradoName: acc.asesoradoName,
                avatarUrl: acc.avatarUrl,
                routineName: acc.routineName,
                seriesCompleted: completed,
                seriesAssigned: assigned,
                completionPercentage: percentage,
              );
            }).toList()
            ..sort((a, b) {
              final nameCompare = a.asesoradoName.compareTo(b.asesoradoName);
              if (nameCompare != 0) {
                return nameCompare;
              }
              return b.completionPercentage.compareTo(a.completionPercentage);
            });

      final result = RoutineReportData(
        mostUsedRoutines: mostUsedRoutines,
        exerciseCompletion: const {},
        adherenceByAsesorado: const {},
        routineProgress: progressData,
      );

      _setCacheData(cacheKey, result);
      return result;
    } catch (e, s) {
      developer.log(
        'Error al generar reporte de rutinas: $e',
        name: 'ReportsService',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<MetricsReportData> generateMetricsReport({
    required int coachId,
    required DateRange dateRange,
    int? asesoradoId,
  }) async {
    try {
      final cacheKey = _generateCacheKey(
        'metricas',
        coachId,
        dateRange,
        asesoradoId,
      );
      final cachedData = _getCacheData(cacheKey);
      if (cachedData != null) {
        return cachedData as MetricsReportData;
      }

      developer.log(
        'Generando reporte de métricas para coach $coachId',
        name: 'ReportsService',
      );

      final metricsQuery = '''
        SELECT 
          a.nombre as asesorado_name,
          a.avatar_url,
          m.fecha_medicion,
          m.peso,
          m.porcentaje_grasa,
          m.imc,
          m.masa_muscular
        FROM mediciones m
        JOIN asesorados a ON m.asesorado_id = a.id
        WHERE a.coach_id = ?
          AND m.fecha_medicion BETWEEN ? AND ?
          ${asesoradoId != null ? 'AND a.id = ?' : ''}
        ORDER BY a.id, m.fecha_medicion ASC
      ''';

      final params = [
        coachId,
        dateRange.startDate.toIso8601String().split('T')[0],
        dateRange.endDate.toIso8601String().split('T')[0],
        if (asesoradoId != null) asesoradoId,
      ];

      final results = await _db.query(metricsQuery, params);

      final evolution =
          results
              .map(
                (r) => MetricsEvolution(
                  asesoradoName: r.fields['asesorado_name']?.toString() ?? '',
                  avatarUrl: r.fields['avatar_url']?.toString(),
                  measurementDate: DateTime.parse(
                    r.fields['fecha_medicion'].toString(),
                  ),
                  weight: double.tryParse(r.fields['peso']?.toString() ?? ''),
                  fatPercentage: double.tryParse(
                    r.fields['porcentaje_grasa']?.toString() ?? '',
                  ),
                  imc: double.tryParse(r.fields['imc']?.toString() ?? ''),
                  muscleMass: double.tryParse(
                    r.fields['masa_muscular']?.toString() ?? '',
                  ),
                ),
              )
              .toList();

      final summaryList = await _getMetricsSummary(
        coachId,
        dateRange,
        asesoradoId,
      );

      final significantChanges = _calculateSignificantChanges(
        evolution,
        dateRange,
      );

      final result = MetricsReportData(
        evolution: evolution,
        summaryByAsesorado: summaryList,
        significantChanges: significantChanges,
      );

      _setCacheData(cacheKey, result);
      return result;
    } catch (e, s) {
      developer.log(
        'Error al generar reporte de métricas: $e',
        name: 'ReportsService',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<List<MetricsSummary>> _getMetricsSummary(
    int coachId,
    DateRange dateRange,
    int? asesoradoId,
  ) async {
    try {
      final dateStr1 = dateRange.startDate.toIso8601String().split('T')[0];
      final dateStr2 = dateRange.endDate.toIso8601String().split('T')[0];

      final query = '''
        SELECT 
          a.id,
          a.nombre,
          a.avatar_url,
          a.objetivo_principal,
          a.objetivo_secundario,
          (SELECT m.peso FROM mediciones m 
           WHERE m.asesorado_id = a.id 
           AND m.fecha_medicion BETWEEN ? AND ?
           ORDER BY m.fecha_medicion ASC LIMIT 1) as initial_weight,
          (SELECT m.peso FROM mediciones m 
           WHERE m.asesorado_id = a.id 
           AND m.fecha_medicion BETWEEN ? AND ?
           ORDER BY m.fecha_medicion DESC LIMIT 1) as current_weight,
          (SELECT m.porcentaje_grasa FROM mediciones m 
           WHERE m.asesorado_id = a.id 
           AND m.fecha_medicion BETWEEN ? AND ?
           ORDER BY m.fecha_medicion ASC LIMIT 1) as initial_fat,
          (SELECT m.porcentaje_grasa FROM mediciones m 
           WHERE m.asesorado_id = a.id 
           AND m.fecha_medicion BETWEEN ? AND ?
           ORDER BY m.fecha_medicion DESC LIMIT 1) as current_fat,
          COUNT(m.id) as measurement_count
        FROM asesorados a
        LEFT JOIN mediciones m ON a.id = m.asesorado_id
          AND m.fecha_medicion BETWEEN ? AND ?
        WHERE a.coach_id = ?
          ${asesoradoId != null ? 'AND a.id = ?' : ''}
        GROUP BY a.id, a.nombre, a.objetivo_principal, a.objetivo_secundario
      ''';

      final params = [
        dateStr1,
        dateStr2,
        dateStr1,
        dateStr2,
        dateStr1,
        dateStr2,
        dateStr1,
        dateStr2,
        dateStr1,
        dateStr2,
        coachId,
        if (asesoradoId != null) asesoradoId,
      ];

      final results = await _db.query(query, params);
      final summary = <MetricsSummary>[];

      for (final r in results) {
        final name = r.fields['nombre']?.toString() ?? '';
        final avatarUrl = r.fields['avatar_url']?.toString();
        final initialWeight = double.tryParse(
          r.fields['initial_weight']?.toString() ?? '',
        );
        final currentWeight = double.tryParse(
          r.fields['current_weight']?.toString() ?? '',
        );
        final initialFat = double.tryParse(
          r.fields['initial_fat']?.toString() ?? '',
        );
        final currentFat = double.tryParse(
          r.fields['current_fat']?.toString() ?? '',
        );
        final objetivoPrincipal = r.fields['objetivo_principal']?.toString();
        final objetivoSecundario = r.fields['objetivo_secundario']?.toString();

        double? weightChange;
        if (initialWeight != null && currentWeight != null) {
          weightChange = currentWeight - initialWeight;
        }

        double? fatChange;
        if (initialFat != null && currentFat != null) {
          fatChange = currentFat - initialFat;
        }

        summary.add(
          MetricsSummary(
            asesoradoName: name,
            avatarUrl: avatarUrl,
            initialWeight: initialWeight,
            currentWeight: currentWeight,
            weightChange: weightChange,
            initialFat: initialFat,
            currentFat: currentFat,
            fatChange: fatChange,
            measurementCount:
                int.tryParse(r.fields['measurement_count'].toString()) ?? 0,
            objetivoPrincipal:
                objetivoPrincipal?.isNotEmpty == true
                    ? objetivoPrincipal
                    : null,
            objetivoSecundario:
                objetivoSecundario?.isNotEmpty == true
                    ? objetivoSecundario
                    : null,
          ),
        );
      }

      return summary;
    } catch (e, s) {
      developer.log(
        'Error al obtener resumen de métricas: $e',
        name: 'ReportsService',
        error: e,
        stackTrace: s,
      );
      return [];
    }
  }

  List<MetricsChange> _calculateSignificantChanges(
    List<MetricsEvolution> evolution,
    DateRange dateRange,
  ) {
    try {
      final changes = <MetricsChange>[];
      final byAsesorado = <String, List<MetricsEvolution>>{};

      for (final metric in evolution) {
        byAsesorado.putIfAbsent(metric.asesoradoName, () => []).add(metric);
      }

      for (final entry in byAsesorado.entries) {
        final metrics = entry.value;

        if (metrics.length >= 2) {
          final first = metrics.first;
          final last = metrics.last;

          if (first.weight != null && last.weight != null) {
            final change = last.weight! - first.weight!;
            final changePercent = (change / first.weight! * 100).abs();

            if (changePercent > 2) {
              changes.add(
                MetricsChange(
                  asesoradoName: entry.key,
                  avatarUrl: first.avatarUrl,
                  metric: 'Peso',
                  change: change,
                  changePercentage: changePercent,
                  startDate: first.measurementDate,
                  endDate: last.measurementDate,
                ),
              );
            }
          }

          if (first.fatPercentage != null && last.fatPercentage != null) {
            final change = last.fatPercentage! - first.fatPercentage!;
            final changePercent = (change / first.fatPercentage! * 100).abs();

            if (changePercent > 2) {
              changes.add(
                MetricsChange(
                  asesoradoName: entry.key,
                  avatarUrl: first.avatarUrl,
                  metric: 'Porcentaje de grasa',
                  change: change,
                  changePercentage: changePercent,
                  startDate: first.measurementDate,
                  endDate: last.measurementDate,
                ),
              );
            }
          }
        }
      }

      return changes;
    } catch (e, s) {
      developer.log(
        'Error al calcular cambios significativos: $e',
        name: 'ReportsService',
        error: e,
        stackTrace: s,
      );
      return [];
    }
  }

  Future<BitacoraReportData> generateBitacoraReport({
    required int coachId,
    required DateRange dateRange,
    int? asesoradoId,
  }) async {
    try {
      final cacheKey = _generateCacheKey(
        'bitacora',
        coachId,
        dateRange,
        asesoradoId,
      );
      final cachedData = _getCacheData(cacheKey);
      if (cachedData != null) {
        return cachedData as BitacoraReportData;
      }

      developer.log(
        'Generando reporte de bitácora para coach $coachId',
        name: 'ReportsService',
      );

      final notesQuery = '''
        SELECT 
          n.id,
          n.asesorado_id,
          a.nombre as asesorado_name,
          a.avatar_url,
          n.contenido,
          n.fecha_creacion,
          n.prioritaria
        FROM notas n
        JOIN asesorados a ON n.asesorado_id = a.id
        WHERE a.coach_id = ?
          AND n.fecha_creacion BETWEEN ? AND ?
          ${asesoradoId != null ? 'AND n.asesorado_id = ?' : ''}
        ORDER BY n.fecha_creacion DESC
      ''';

      final params = [
        coachId,
        dateRange.startDate.toIso8601String(),
        dateRange.endDate.toIso8601String(),
        if (asesoradoId != null) asesoradoId,
      ];

      final results = await _db.query(notesQuery, params);

      int totalNotes = 0;
      int priorityNotes = 0;
      final notesByAsesorado = <String, int>{};
      final noteEntries = <NoteEntry>[];

      for (final r in results) {
        totalNotes++;
        final isPriority =
            r.fields['prioritaria'] == 1 || r.fields['prioritaria'] == true;
        if (isPriority) priorityNotes++;

        final asesoradoName = r.fields['asesorado_name']?.toString() ?? '';
        notesByAsesorado[asesoradoName] =
            (notesByAsesorado[asesoradoName] ?? 0) + 1;

        noteEntries.add(
          NoteEntry(
            id: int.tryParse(r.fields['id'].toString()) ?? 0,
            asesoradoName: asesoradoName,
            avatarUrl: r.fields['avatar_url']?.toString(),
            content: r.fields['contenido']?.toString() ?? '',
            createdAt: DateTime.parse(r.fields['fecha_creacion'].toString()),
            isPriority: isPriority,
          ),
        );
      }

      final objectiveTracking = _parseObjectiveTracking(noteEntries);

      final result = BitacoraReportData(
        totalNotes: totalNotes,
        priorityNotes: priorityNotes,
        notesByPeriod: noteEntries,
        notesByAsesorado: notesByAsesorado,
        objectiveTracking: objectiveTracking,
      );

      _setCacheData(cacheKey, result);
      return result;
    } catch (e, s) {
      developer.log(
        'Error al generar reporte de bitácora: $e',
        name: 'ReportsService',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  List<ObjectiveTracking> _parseObjectiveTracking(List<NoteEntry> notes) {
    try {
      final tracking = <String, ObjectiveTracking>{};
      final objectiveKeywords = [
        'objetivo',
        'meta',
        'goal',
        'progreso',
        'avance',
      ];

      for (final note in notes) {
        final contentLower = note.content.toLowerCase();
        final matchedKeywords = <String>[];

        // Encontrar todos los keywords que coinciden en la nota
        for (final keyword in objectiveKeywords) {
          if (contentLower.contains(keyword)) {
            matchedKeywords.add(keyword);
          }
        }

        // Procesar cada keyword encontrado
        for (final keyword in matchedKeywords) {
          final key = '${note.asesoradoName}_$keyword';
          if (tracking.containsKey(key)) {
            final existing = tracking[key]!;
            tracking[key] = ObjectiveTracking(
              asesoradoName: existing.asesoradoName,
              avatarUrl: existing.avatarUrl,
              objective: existing.objective,
              notesCount: existing.notesCount + 1,
              firstNote: existing.firstNote,
              lastNote:
                  note.createdAt.isAfter(existing.lastNote)
                      ? note.createdAt
                      : existing.lastNote,
            );
          } else {
            tracking[key] = ObjectiveTracking(
              asesoradoName: note.asesoradoName,
              avatarUrl: note.avatarUrl,
              objective: keyword,
              notesCount: 1,
              firstNote: note.createdAt,
              lastNote: note.createdAt,
            );
          }
        }
      }

      return tracking.values.toList();
    } catch (e, s) {
      developer.log(
        'Error al parsear rastreo de objetivos: $e',
        name: 'ReportsService',
        error: e,
        stackTrace: s,
      );
      return [];
    }
  }

  Future<ConsolidatedReportData> generateConsolidatedReport({
    required int coachId,
    required DateRange dateRange,
    int? asesoradoId,
  }) async {
    try {
      developer.log(
        'Generando reporte consolidado para coach $coachId',
        name: 'ReportsService',
      );

      // Ejecutar todas las generaciones de reportes en paralelo para reducir tiempo total
      final results = await Future.wait([
        generatePaymentReport(
          coachId: coachId,
          dateRange: dateRange,
          asesoradoId: asesoradoId,
        ),
        generateRoutineReport(
          coachId: coachId,
          dateRange: dateRange,
          asesoradoId: asesoradoId,
        ),
        generateMetricsReport(
          coachId: coachId,
          dateRange: dateRange,
          asesoradoId: asesoradoId,
        ),
        generateBitacoraReport(
          coachId: coachId,
          dateRange: dateRange,
          asesoradoId: asesoradoId,
        ),
      ]);

      return ConsolidatedReportData(
        paymentData: results[0] as PaymentReportData,
        routineData: results[1] as RoutineReportData,
        metricsData: results[2] as MetricsReportData,
        bitacoraData: results[3] as BitacoraReportData,
        generatedAt: DateTime.now(),
      );
    } catch (e, s) {
      developer.log(
        'Error al generar reporte consolidado: $e',
        name: 'ReportsService',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }
}
