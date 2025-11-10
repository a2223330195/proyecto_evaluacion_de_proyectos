// lib/services/data_seeder_service.dart
import 'dart:developer' as developer;

/// Servicio para poblar la base de datos con datos iniciales (ejercicios)
///
/// NOTA: El seeding desde JSON ha sido deshabilitado.
/// La tabla ejercicios_maestro debe ser poblada usando SQL:
/// mysql -u root -p coachhub_db < lib/db/ejercicios_maestro_generated.sql
class DataSeederService {
  /// Seeding deshabilitado - usa SQL directamente
  static Future<void> seedEjerciciosMaestro() async {
    try {
      developer.log(
        'Seeding de ejercicios maestros: DESHABILITADO (usar BD SQL directamente)',
        name: 'DataSeederService',
        level: 800,
      );

      // Seeding desde JSON deshabilitado.
      // La tabla ejercicios_maestro debe ser poblada desde SQL:
      // mysql -u root -p coachhub_db < lib/db/ejercicios_maestro_generated.sql

      return;
    } catch (e, s) {
      developer.log(
        '❌ Error en seedEjerciciosMaestro(): $e',
        name: 'DataSeederService',
        error: e,
        stackTrace: s,
        level: 1000,
      );
    }
  }
}
