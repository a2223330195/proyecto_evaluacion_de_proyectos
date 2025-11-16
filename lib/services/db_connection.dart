// lib/services/db_connection.dart

import 'dart:developer' as developer;
import 'dart:async';
import 'package:mysql1/mysql1.dart';
import 'package:coachhub/services/data_seeder_service.dart';

class DatabaseConnection {
  // Configuración de la conexión con tus datos
  static final _settings = ConnectionSettings(
    host: 'localhost', // O la IP de tu servidor de base de datos
    port: 3306, // Puerto por defecto de MySQL
    user: 'root', // O un usuario que crees para la app
    password: '123456789', // La contraseña que especificaste
    db: 'coachhub_db',
  );

  // Instancia Singleton para no crear múltiples conexiones
  DatabaseConnection._privateConstructor();
  static final DatabaseConnection instance =
      DatabaseConnection._privateConstructor();

  MySqlConnection? _connection;
  static bool _schemaEnsured = false;
  static bool _seeded = false;

  // Método para obtener la conexión (reutiliza la conexión si está activa)
  Future<MySqlConnection> get connection async {
    // Si la conexión no existe, crea una nueva.
    if (_connection == null) {
      developer.log(
        'Conexión no existente. Estableciendo nueva conexión a MySQL...',
        name: 'DatabaseConnection',
      );
      final conn = await MySqlConnection.connect(_settings);
      if (!_schemaEnsured) {
        try {
          await _ensureSchema(conn);
          _schemaEnsured = true;
        } on MySqlException catch (e) {
          if (e.errorNumber == 1060 || e.errorNumber == 1061) {
            developer.log(
              'Esquema ya estaba ajustado. Continuando.',
              name: 'DatabaseConnection',
              error: e,
              level: 800,
            );
            _schemaEnsured = true;
          } else {
            rethrow;
          }
        }
      }

      // Asignar conexión ANTES del seeding para que sea reutilizada
      _connection = conn;

      // Realizar seeding de ejercicios maestros si no se ha hecho
      if (!_seeded) {
        try {
          developer.log(
            'Iniciando seeding de ejercicios maestros desde JSON...',
            name: 'DatabaseConnection',
          );
          await DataSeederService.seedEjerciciosMaestro();
          _seeded = true;
        } catch (e) {
          developer.log(
            'Error durante seeding: $e',
            name: 'DatabaseConnection',
            error: e,
            level: 900,
          );
          // Continuar aunque falle el seeding
        }
      }
    } else {
      developer.log(
        'Reutilizando conexión a MySQL existente.',
        name: 'DatabaseConnection',
      );
    }
    // Devuelve la conexión (ya sea la nueva o la existente)
    return _connection!;
  }

  // Método para cerrar la conexión
  Future<void> close() async {
    // Comentado para evitar el cierre prematuro de la conexión singleton.
    // La clase ya gestiona la reconexión si el socket se pierde.
    // await _connection?.close();
    // _connection = null;
    developer.log(
      'ADVERTENCIA: Se intentó cerrar la conexión de la base de datos global.',
      name: 'DatabaseConnection',
      level: 900, // level > 800 suele indicar warning/error según convención
    );
  }

  // Método de query con reintentos automáticos para evitar "packets out of order"
  Future<Results> query(String sql, [List<Object?>? params]) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final conn = await connection;

        // Usar consulta con parámetros
        if (params != null && params.isNotEmpty) {
          try {
            final results = await conn.query(sql, params);
            return results;
          } on MySqlException catch (e) {
            _handleMySqlError(e, sql, retryCount);
            if (retryCount < maxRetries - 1) {
              retryCount++;
              await Future.delayed(Duration(milliseconds: 100 * retryCount));
              continue;
            }
            rethrow;
          }
        }

        // Usar consulta directa si no hay parámetros
        try {
          return await conn.query(sql);
        } on MySqlException catch (e) {
          _handleMySqlError(e, sql, retryCount);
          if (retryCount < maxRetries - 1) {
            retryCount++;
            await Future.delayed(Duration(milliseconds: 100 * retryCount));
            continue;
          }
          rethrow;
        }
      } catch (e, s) {
        developer.log(
          'Error en query (intento $retryCount/$maxRetries): $sql\nError: $e',
          name: 'DatabaseConnection',
          error: e,
          stackTrace: s,
          level: 900,
        );

        if (retryCount < maxRetries - 1) {
          retryCount++;
          await Future.delayed(Duration(milliseconds: 100 * retryCount));
        } else {
          rethrow;
        }
      }
    }

    throw Exception('Query fallida después de $maxRetries intentos: $sql');
  }

  /// Maneja errores de MySQL
  void _handleMySqlError(MySqlException e, String sql, int retryCount) {
    if (e.errorNumber == 1156 ||
        e.errorNumber == 2006 ||
        e.errorNumber == 2013) {
      // Conexión corrupta o perdida - reintentar
      developer.log(
        'Conexión MySQL corrupta (Error ${e.errorNumber}). Intento ${retryCount + 1}...',
        name: 'DatabaseConnection',
        error: e,
        level: 800,
      );
      _connection?.close();
      _connection = null;
      _schemaEnsured = false;
    } else {
      // Otro error - no reintentar
      developer.log(
        'Error MySQL no recuperable: ${e.errorNumber} - ${e.message}',
        name: 'DatabaseConnection',
        error: e,
        level: 900,
      );
    }
  }

  // /// Método para escapar valores y prevenir SQL Injection
  // /// Este método está causando un error 'undefined_method' si el paquete mysql1
  // /// no está actualizado a una versión que incluya `conn.escape()`.
  // /// La solución recomendada es actualizar el paquete `mysql1`.
  // Future<String> escape(Object? value) async {
  //   final conn = await connection;
  //   return conn.escape(value);
  // }

  Future<void> _ensureSchema(MySqlConnection conn) async {
    try {
      // Esperar un poco antes de empezar
      await Future.delayed(const Duration(milliseconds: 100));

      // Verificar si la columna batch_id existe
      final batchColumn = await conn.query(
        "SHOW COLUMNS FROM asignaciones_agenda LIKE 'batch_id'",
      );
      await Future.delayed(const Duration(milliseconds: 100));

      // Si NO existe, agregarla
      if (batchColumn.isEmpty) {
        developer.log(
          'Añadiendo columna batch_id faltante en asignaciones_agenda',
          name: 'DatabaseConnection',
        );
        try {
          await conn.query(
            'ALTER TABLE asignaciones_agenda ADD COLUMN batch_id INT NULL AFTER plantilla_id',
          );
          await Future.delayed(const Duration(milliseconds: 100));
        } on MySqlException catch (e) {
          if (e.errorNumber == 1060) {
            developer.log(
              'Columna batch_id ya existía, omitiendo ALTER TABLE.',
              name: 'DatabaseConnection',
              level: 800,
            );
          } else {
            rethrow;
          }
        }
      }

      // Verificar si el constraint FOREIGN KEY ya existe
      await Future.delayed(const Duration(milliseconds: 100));
      final existingConstraint = await conn.query(
        "SELECT CONSTRAINT_NAME FROM information_schema.KEY_COLUMN_USAGE "
        "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'asignaciones_agenda' "
        "AND COLUMN_NAME = 'batch_id' AND REFERENCED_TABLE_NAME = 'rutina_batches'",
      );
      await Future.delayed(const Duration(milliseconds: 100));

      // Si NO existe, crearlo
      if (existingConstraint.isEmpty) {
        developer.log(
          'Creando foreign key para batch_id en asignaciones_agenda',
          name: 'DatabaseConnection',
        );
        try {
          await conn.query(
            'ALTER TABLE asignaciones_agenda '
            'ADD CONSTRAINT fk_asignaciones_batch '
            'FOREIGN KEY (batch_id) REFERENCES rutina_batches(id) '
            'ON DELETE SET NULL',
          );
          await Future.delayed(const Duration(milliseconds: 100));
        } on MySqlException catch (e) {
          if (e.errorNumber == 1061) {
            developer.log(
              'Constraint fk_asignaciones_batch ya existía, omitiendo ALTER TABLE.',
              name: 'DatabaseConnection',
              level: 800,
            );
          } else {
            rethrow;
          }
        }
      }

      // Verificar si la tabla ejercicios_maestro tiene datos
      await Future.delayed(const Duration(milliseconds: 100));
      final ejerciciosCount = await conn.query(
        'SELECT COUNT(*) as count FROM ejercicios_maestro',
      );
      final count = ejerciciosCount.first['count'] as int;

      if (count == 0) {
        developer.log(
          'Tabla ejercicios_maestro vacía. Insertando ejercicios iniciales...',
          name: 'DatabaseConnection',
        );
        // Insertar ejercicios iniciales (mínimo 10 para que la app funcione)
        final basicExercises = [
          "('Pechada', 'pecho', 'mancuerna', NULL, 'coachhub')",
          "('Flexiones', 'pecho', 'solo cuerpo', NULL, 'coachhub')",
          "('Press de Banca', 'pecho', 'mancuerna', NULL, 'coachhub')",
          "('Sentadilla', 'cuádriceps', 'mancuerna', NULL, 'coachhub')",
          "('Peso Muerto', 'espalda baja', 'mancuerna', NULL, 'coachhub')",
          "('Remo', 'espalda media', 'mancuerna', NULL, 'coachhub')",
          "('Pull-up', 'Los lats', 'solo cuerpo', NULL, 'coachhub')",
          "('Curl de Bíceps', 'bíceps', 'mancuerna', NULL, 'coachhub')",
          "('Extensión de Tríceps', 'tríceps', 'mancuerna', NULL, 'coachhub')",
          "('Press de Hombro', 'hombros', 'mancuerna', NULL, 'coachhub')",
        ];

        for (final exercise in basicExercises) {
          try {
            await conn.query(
              'INSERT IGNORE INTO ejercicios_maestro (nombre, musculo_principal, equipamiento, video_url, fuente) VALUES $exercise',
            );
            await Future.delayed(const Duration(milliseconds: 50));
          } catch (e) {
            developer.log(
              'Error insertando ejercicio: $e',
              name: 'DatabaseConnection',
              level: 800,
            );
          }
        }
        developer.log(
          'Ejercicios iniciales insertados.',
          name: 'DatabaseConnection',
        );
      } else {
        developer.log(
          'Tabla ejercicios_maestro ya tiene $count ejercicios.',
          name: 'DatabaseConnection',
        );
      }
    } on MySqlException catch (e) {
      // Solo ignorar errores 1060 y 1061 (column/constraint ya existe)
      if (e.errorNumber == 1060 || e.errorNumber == 1061) {
        developer.log(
          'Esquema parcialmente ajustado (columna/constraint ya existía).',
          name: 'DatabaseConnection',
          level: 800,
        );
      } else {
        developer.log(
          'Error asegurando el esquema',
          name: 'DatabaseConnection',
          error: e,
          level: 1000,
        );
        rethrow;
      }
    } catch (e, s) {
      developer.log(
        'Error inesperado asegurando el esquema',
        name: 'DatabaseConnection',
        error: e,
        stackTrace: s,
        level: 1000,
      );
      rethrow;
    }
  }
}
