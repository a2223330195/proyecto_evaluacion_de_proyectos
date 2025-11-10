// lib/services/search_service.dart

import 'package:coachhub/models/asesorado_model.dart';
import 'package:coachhub/models/rutina_model.dart';
import 'package:coachhub/services/db_connection.dart';

class SearchService {
  final _db = DatabaseConnection.instance;

  /// Buscar asesorados con filtros combinables
  /// [query]: texto a buscar en nombre
  /// [planId]: filtrar por plan ID
  /// [estadoPago]: filtrar por estado de pago ("activo", "pendiente", "deudor")
  /// [coachId]: filtrar por coach
  Future<List<Asesorado>> buscarAsesorados({
    String? query,
    int? planId,
    String? estadoPago,
    int? coachId,
  }) async {
    String sql = 'SELECT * FROM asesorados WHERE 1=1';
    List<dynamic> params = [];

    // Búsqueda por nombre (parcial)
    if (query != null && query.isNotEmpty) {
      sql += ' AND nombre LIKE ?';
      params.add('%$query%');
    }

    // Filtro por plan
    if (planId != null) {
      sql += ' AND plan_id = ?';
      params.add(planId);
    }

    // Filtro por estado de pago
    if (estadoPago != null && estadoPago.isNotEmpty) {
      sql += ' AND estado_pago = ?';
      params.add(estadoPago);
    }

    // Filtro por coach
    if (coachId != null) {
      sql += ' AND coach_id = ?';
      params.add(coachId);
    }

    sql += ' ORDER BY nombre ASC';

    final results = await _db.query(sql, params);
    return results.map((r) => Asesorado.fromMap(r.fields)).toList();
  }

  /// Buscar rutinas con filtros
  /// [query]: texto a buscar en nombre
  /// [tipo]: filtrar por tipo de rutina (RutinaCategoria)
  /// [nivel]: filtrar por nivel
  /// [duracionMin]: duración mínima de sesiones
  /// [duracionMax]: duración máxima de sesiones
  Future<List<Rutina>> buscarRutinas({
    String? query,
    String? tipo,
    String? nivel,
    int? duracionMin,
    int? duracionMax,
    int? coachId,
  }) async {
    String sql = 'SELECT * FROM rutinas WHERE 1=1';
    List<dynamic> params = [];

    // Búsqueda por nombre (parcial)
    if (query != null && query.isNotEmpty) {
      sql += ' AND nombre LIKE ?';
      params.add('%$query%');
    }

    // Filtro por tipo
    if (tipo != null && tipo.isNotEmpty) {
      sql += ' AND categoria = ?';
      params.add(tipo);
    }

    // Filtro por nivel
    if (nivel != null && nivel.isNotEmpty) {
      sql += ' AND nivel = ?';
      params.add(nivel);
    }

    // Filtro por duración mínima
    if (duracionMin != null) {
      sql += ' AND duracion_sesiones >= ?';
      params.add(duracionMin);
    }

    // Filtro por duración máxima
    if (duracionMax != null) {
      sql += ' AND duracion_sesiones <= ?';
      params.add(duracionMax);
    }

    // Filtro por coach
    if (coachId != null) {
      sql += ' AND creador_coach_id = ?';
      params.add(coachId);
    }

    sql += ' ORDER BY nombre ASC';

    final results = await _db.query(sql, params);
    return results.map((r) => Rutina.fromMap(r.fields)).toList();
  }

  /// Contar resultados de búsqueda de asesorados
  Future<int> contarAsesoradosBusqueda({
    String? query,
    int? planId,
    String? estadoPago,
    int? coachId,
  }) async {
    String sql = 'SELECT COUNT(*) as total FROM asesorados WHERE 1=1';
    List<dynamic> params = [];

    if (query != null && query.isNotEmpty) {
      sql += ' AND nombre LIKE ?';
      params.add('%$query%');
    }
    if (planId != null) {
      sql += ' AND plan_id = ?';
      params.add(planId);
    }
    if (estadoPago != null && estadoPago.isNotEmpty) {
      sql += ' AND estado_pago = ?';
      params.add(estadoPago);
    }
    if (coachId != null) {
      sql += ' AND coach_id = ?';
      params.add(coachId);
    }

    final results = await _db.query(sql, params);
    if (results.isNotEmpty) {
      return results.first.fields['total'] as int? ?? 0;
    }
    return 0;
  }

  /// Contar resultados de búsqueda de rutinas
  Future<int> contarRutinasBusqueda({
    String? query,
    String? tipo,
    String? nivel,
    int? duracionMin,
    int? duracionMax,
    int? coachId,
  }) async {
    String sql = 'SELECT COUNT(*) as total FROM rutinas WHERE 1=1';
    List<dynamic> params = [];

    if (query != null && query.isNotEmpty) {
      sql += ' AND nombre LIKE ?';
      params.add('%$query%');
    }
    if (tipo != null && tipo.isNotEmpty) {
      sql += ' AND categoria = ?';
      params.add(tipo);
    }
    if (nivel != null && nivel.isNotEmpty) {
      sql += ' AND nivel = ?';
      params.add(nivel);
    }
    if (duracionMin != null) {
      sql += ' AND duracion_sesiones >= ?';
      params.add(duracionMin);
    }
    if (duracionMax != null) {
      sql += ' AND duracion_sesiones <= ?';
      params.add(duracionMax);
    }
    if (coachId != null) {
      sql += ' AND creador_coach_id = ?';
      params.add(coachId);
    }

    final results = await _db.query(sql, params);
    if (results.isNotEmpty) {
      return results.first.fields['total'] as int? ?? 0;
    }
    return 0;
  }

  /// Búsqueda avanzada de asesorados con paginación
  Future<List<Asesorado>> buscarAsesoradosPaginado({
    String? query,
    int? planId,
    String? estadoPago,
    int? coachId,
    required int pageNumber,
    int pageSize = 10,
  }) async {
    String sql = 'SELECT * FROM asesorados WHERE 1=1';
    List<dynamic> params = [];

    if (query != null && query.isNotEmpty) {
      sql += ' AND nombre LIKE ?';
      params.add('%$query%');
    }
    if (planId != null) {
      sql += ' AND plan_id = ?';
      params.add(planId);
    }
    if (estadoPago != null && estadoPago.isNotEmpty) {
      sql += ' AND estado_pago = ?';
      params.add(estadoPago);
    }
    if (coachId != null) {
      sql += ' AND coach_id = ?';
      params.add(coachId);
    }

    sql += ' ORDER BY nombre ASC LIMIT ? OFFSET ?';
    final offset = (pageNumber - 1) * pageSize;
    params.addAll([pageSize, offset]);

    final results = await _db.query(sql, params);
    return results.map((r) => Asesorado.fromMap(r.fields)).toList();
  }
}
