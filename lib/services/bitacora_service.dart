// lib/services/bitacora_service.dart

import 'package:coachhub/models/nota_model.dart';
import 'package:coachhub/services/db_connection.dart';

class BitacoraService {
  final _db = DatabaseConnection.instance;

  /// Crear nueva nota en la bitácora
  Future<void> crearNota(Nota nota) async {
    await _db.query(
      '''
  INSERT INTO notas (
        asesorado_id, contenido, prioritaria, 
        fecha_creacion, fecha_actualizacion
      ) VALUES (?, ?, ?, ?, ?)
      ''',
      [
        nota.asesoradoId,
        nota.contenido,
        nota.prioritaria ? 1 : 0,
        nota.fechaCreacion.toIso8601String(),
        nota.fechaActualizacion.toIso8601String(),
      ],
    );
  }

  /// Obtener notas prioritarias de TODOS los asesorados de un coach (para Dashboard)
  Future<List<Nota>> obtenerNotasPrioritariasPorCoach(
    int coachId, {
    int limit = 5,
  }) async {
    final results = await _db.query(
      '''
  SELECT n.*, a.nombre as asesorado_nombre 
      FROM notas n
      JOIN asesorados a ON n.asesorado_id = a.id
      WHERE a.coach_id = ? AND n.prioritaria = 1
      ORDER BY n.fecha_creacion DESC
      LIMIT ?
      ''',
      [coachId, limit],
    );
    return results.map((r) => Nota.fromMap(r.fields)).toList();
  }

  /// Obtener notas prioritarias de un asesorado
  Future<List<Nota>> obtenerNotasPrioritarias(int asesoradoId) async {
    final results = await _db.query(
      '''
  SELECT * FROM notas 
      WHERE asesorado_id = ? AND prioritaria = 1
      ORDER BY fecha_creacion DESC
      ''',
      [asesoradoId],
    );
    return results.map((r) => Nota.fromMap(r.fields)).toList();
  }

  /// Obtener TODAS las notas de un asesorado (ordenadas: prioritarias primero, después más reciente)
  Future<List<Nota>> obtenerTodasLasNotas(int asesoradoId) async {
    final results = await _db.query(
      '''
  SELECT * FROM notas 
      WHERE asesorado_id = ?
      ORDER BY prioritaria DESC, fecha_creacion DESC
      ''',
      [asesoradoId],
    );
    return results.map((r) => Nota.fromMap(r.fields)).toList();
  }

  /// Obtener todas las notas con paginación (prioritarias primero, después más reciente)
  Future<List<Nota>> obtenerNotasPaginadas({
    required int asesoradoId,
    required int pageNumber,
    int pageSize = 10,
  }) async {
    final offset = (pageNumber - 1) * pageSize;
    final results = await _db.query(
      '''
  SELECT * FROM notas 
      WHERE asesorado_id = ?
      ORDER BY prioritaria DESC, fecha_creacion DESC
      LIMIT ? OFFSET ?
      ''',
      [asesoradoId, pageSize, offset],
    );
    return results.map((r) => Nota.fromMap(r.fields)).toList();
  }

  /// Contar total de notas para un asesorado
  Future<int> contarNotas(int asesoradoId) async {
    final results = await _db.query(
      'SELECT COUNT(*) as total FROM notas WHERE asesorado_id = ?',
      [asesoradoId],
    );
    if (results.isNotEmpty) {
      return results.first.fields['total'] as int? ?? 0;
    }
    return 0;
  }

  /// Actualizar una nota existente
  Future<void> actualizarNota(Nota nota) async {
    await _db.query(
      '''
  UPDATE notas 
      SET contenido = ?, prioritaria = ?
      WHERE id = ?
      ''',
      [nota.contenido, nota.prioritaria ? 1 : 0, nota.id],
    );
  }

  /// Eliminar una nota
  Future<void> eliminarNota(int notaId) async {
    await _db.query('DELETE FROM notas WHERE id = ?', [notaId]);
  }

  /// Marcar/desmarcar una nota como prioritaria
  Future<void> togglePrioritaria(int notaId, bool prioritaria) async {
    await _db.query(
      '''
  UPDATE notas 
      SET prioritaria = ?
      WHERE id = ?
      ''',
      [prioritaria ? 1 : 0, notaId],
    );
  }

  /// Buscar notas por contenido
  Future<List<Nota>> buscarNotas(int asesoradoId, String query) async {
    final results = await _db.query(
      '''
  SELECT * FROM notas 
      WHERE asesorado_id = ? AND contenido LIKE ?
      ORDER BY fecha_creacion DESC
      ''',
      [asesoradoId, '%$query%'],
    );
    return results.map((r) => Nota.fromMap(r.fields)).toList();
  }
}
