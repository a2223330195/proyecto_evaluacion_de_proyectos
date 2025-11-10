import 'package:coachhub/services/db_connection.dart';
import 'package:coachhub/models/asesorado_model.dart';

/// PaginationService - Lazy loading pagination para listas grandes
/// Carga items en lotes de pageSize (default 10)
/// Reduce memory footprint y mejora rendimiento
class PaginationService {
  static const int defaultPageSize = 10;

  final DatabaseConnection _db = DatabaseConnection.instance;
  int _pageSize = defaultPageSize;

  PaginationService({int pageSize = defaultPageSize}) {
    _pageSize = pageSize;
  }

  /// Carga una página de asesorados con filtros opcionales
  /// [pageNumber] - página a cargar (1-indexed)
  /// [coachId] - filtro por coach (opcional, si no se proporciona trae todos)
  /// [searchQuery] - búsqueda por nombre (opcional)
  /// [statusFilter] - filtro por estado (opcional)
  Future<List<Asesorado>> loadAsesoradosPage({
    required int pageNumber,
    int? coachId,
    String? searchQuery,
    AsesoradoStatus? statusFilter,
  }) async {
    final offset = (pageNumber - 1) * _pageSize;

    String whereClause = '';
    List<Object?> params = [];

    if (coachId != null) {
      whereClause += 'a.coach_id = ?';
      params.add(coachId);
    }

    if (searchQuery?.isNotEmpty ?? false) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      whereClause += 'a.nombre LIKE ?';
      params.add('%$searchQuery%');
    }

    if (statusFilter != null) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      whereClause += 'a.status = ?';
      params.add(statusFilter.name);
    }

    final sql = '''
      SELECT a.*, p.nombre AS plan_nombre
      FROM asesorados a
      LEFT JOIN planes p ON a.plan_id = p.id
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      ORDER BY a.nombre
      LIMIT ? OFFSET ?
    ''';

    params.add(_pageSize);
    params.add(offset);

    final results = await _db.query(sql, params);
    return results.map((row) => Asesorado.fromMap(row.fields)).toList();
  }

  /// Obtiene el total de asesorados con filtros opcionales
  /// Útil para calcular total de páginas
  Future<int> getAsesoradosCount({
    String? searchQuery,
    AsesoradoStatus? statusFilter,
  }) async {
    String whereClause = '';
    List<Object?> params = [];

    if (searchQuery?.isNotEmpty ?? false) {
      whereClause += 'nombre LIKE ?';
      params.add('%$searchQuery%');
    }

    if (statusFilter != null) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      whereClause += 'status = ?';
      params.add(statusFilter.name);
    }

    final sql = '''
      SELECT COUNT(*) as total
      FROM asesorados a
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
    ''';

    final results = await _db.query(sql, params);
    if (results.isNotEmpty) {
      return results.first.fields['total'] as int? ?? 0;
    }
    return 0;
  }

  /// Calcula total de páginas
  Future<int> getTotalPages({
    String? searchQuery,
    AsesoradoStatus? statusFilter,
  }) async {
    final count = await getAsesoradosCount(
      searchQuery: searchQuery,
      statusFilter: statusFilter,
    );
    return (count / _pageSize).ceil();
  }

  /// Setter para cambiar tamaño de página
  void setPageSize(int newPageSize) {
    if (newPageSize > 0) {
      _pageSize = newPageSize;
    }
  }

  /// Getter para tamaño de página
  int get pageSize => _pageSize;
}
