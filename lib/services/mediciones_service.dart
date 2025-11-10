import 'package:coachhub/services/db_connection.dart';
import 'package:coachhub/models/medicion_model.dart';

class MedicionesService {
  final _db = DatabaseConnection.instance;

  Future<List<Medicion>> getMedicionesByAsesorado(int asesoradoId) async {
    final results = await _db.query(
      'SELECT * FROM mediciones WHERE asesorado_id = ? ORDER BY fecha_medicion ASC',
      [asesoradoId],
    );
    return results.map((r) => Medicion.fromMap(r.fields)).toList();
  }

  Future<List<Medicion>> getLatestMediciones(
    int asesoradoId, {
    int limit = 5,
  }) async {
    final results = await _db.query(
      'SELECT * FROM mediciones WHERE asesorado_id = ? ORDER BY fecha_medicion DESC LIMIT ?',
      [asesoradoId, limit],
    );
    // results are DESC, return reversed to be ASC
    final list = results.map((r) => Medicion.fromMap(r.fields)).toList();
    return list.reversed.toList();
  }

  Future<void> createMedicion({
    required int asesoradoId,
    required DateTime fechaMedicion,
    double? peso,
    double? porcentajeGrasa,
    double? imc,
    double? masaMuscular,
    double? aguaCorporal,
    double? pechoCm,
    double? cinturaCm,
    double? caderaCm,
    double? brazoIzqCm,
    double? brazoDerCm,
    double? piernaIzqCm,
    double? piernaDerCm,
    double? pantorrillaIzqCm,
    double? pantorrillaDerCm,
    double? frecuenciaCardiaca,
    double? recordResistencia,
  }) async {
    const sql = '''
      INSERT INTO mediciones (
        asesorado_id, fecha_medicion, peso, porcentaje_grasa, imc, masa_muscular, agua_corporal,
        pecho_cm, cintura_cm, cadera_cm, brazo_izq_cm, brazo_der_cm, pierna_izq_cm, pierna_der_cm,
        pantorrilla_izq_cm, pantorrilla_der_cm, frecuencia_cardiaca, record_resistencia
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''';

    final fechaStr = fechaMedicion.toIso8601String().split('T').first;
    await _db.query(sql, <Object?>[
      asesoradoId,
      fechaStr,
      peso,
      porcentajeGrasa,
      imc,
      masaMuscular,
      aguaCorporal,
      pechoCm,
      cinturaCm,
      caderaCm,
      brazoIzqCm,
      brazoDerCm,
      piernaIzqCm,
      piernaDerCm,
      pantorrillaIzqCm,
      pantorrillaDerCm,
      frecuenciaCardiaca,
      recordResistencia,
    ]);
  }

  Future<void> updateMedicion({
    required int id,
    required DateTime fechaMedicion,
    double? peso,
    double? porcentajeGrasa,
    double? imc,
    double? masaMuscular,
    double? aguaCorporal,
    double? pechoCm,
    double? cinturaCm,
    double? caderaCm,
    double? brazoIzqCm,
    double? brazoDerCm,
    double? piernaIzqCm,
    double? piernaDerCm,
    double? pantorrillaIzqCm,
    double? pantorrillaDerCm,
    double? frecuenciaCardiaca,
    double? recordResistencia,
  }) async {
    const sql = '''
      UPDATE mediciones 
      SET fecha_medicion = ?, peso = ?, porcentaje_grasa = ?, imc = ?, masa_muscular = ?, agua_corporal = ?,
          pecho_cm = ?, cintura_cm = ?, cadera_cm = ?, brazo_izq_cm = ?, brazo_der_cm = ?, pierna_izq_cm = ?,
          pierna_der_cm = ?, pantorrilla_izq_cm = ?, pantorrilla_der_cm = ?, frecuencia_cardiaca = ?,
          record_resistencia = ?
      WHERE id = ?
    ''';
    final fechaStr = fechaMedicion.toIso8601String().split('T').first;
    await _db.query(sql, <Object?>[
      fechaStr,
      peso,
      porcentajeGrasa,
      imc,
      masaMuscular,
      aguaCorporal,
      pechoCm,
      cinturaCm,
      caderaCm,
      brazoIzqCm,
      brazoDerCm,
      piernaIzqCm,
      piernaDerCm,
      pantorrillaIzqCm,
      pantorrillaDerCm,
      frecuenciaCardiaca,
      recordResistencia,
      id,
    ]);
  }

  Future<void> deleteMedicion(int id) async {
    final sql = 'DELETE FROM mediciones WHERE id = ?';
    await _db.query(sql, <Object?>[id]);
  }
}
