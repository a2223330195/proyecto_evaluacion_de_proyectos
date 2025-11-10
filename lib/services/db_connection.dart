// lib/services/db_connection.dart

import 'dart:developer' as developer;
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

  // Método de query (Robusto)
  Future<Results> query(String sql, [List<Object?>? params]) async {
    try {
      final conn = await connection;

      // Usar consulta con parámetros
      if (params != null && params.isNotEmpty) {
        developer.log(
          'Ejecutando consulta con parámetros: $sql con Parámetros: $params',
          name: 'DatabaseConnection',
        );
        final results = await conn.query(sql, params);

        // Log detallado del resultado
        if (results.isNotEmpty) {
          developer.log(
            'Resultado de la consulta:\n'
            'Número de filas: ${results.length}\n'
            'Nombres de columnas: ${results.fields.map((f) => f.name).toList()}\n'
            'Primera fila: ${results.first.fields}\n'
            'Tipos de datos: ${results.fields.map((f) => "${f.name}: ${f.type}").toList()}',
            name: 'DatabaseConnection',
          );
        }

        return results;
      }

      // Usar consulta directa si no hay parámetros
      developer.log(
        'Ejecutando consulta directa: $sql',
        name: 'DatabaseConnection',
      );
      return await conn.query(sql);
    } on MySqlException catch (e) {
      // Códigos de error comunes para conexiones perdidas (ej. 2006, 2013)
      if (e.errorNumber == 2006 || e.errorNumber == 2013) {
        // Conexión perdida. Cierra la conexión vieja (si existe).
        await _connection?.close();
        _connection = null;

        // Intenta de nuevo UNA vez más con una conexión fresca
        // Intenta la consulta de nuevo con una conexión fresca
        return await query(sql, params); // Usa el método recursivamente
      } else {
        // Log non-recoverable MySQL exceptions for debugging
        developer.log(
          'MySqlException en query: $sql',
          name: 'DatabaseConnection',
          error: e,
        );
        rethrow;
      }
    } catch (e, s) {
      // Registra el error y el stacktrace para facilitar diagnóstico
      developer.log(
        'Error inesperado en query: $sql',
        name: 'DatabaseConnection',
        error: e,
        stackTrace: s,
      );
      rethrow;
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
      // Verificar si la columna batch_id existe
      final batchColumn = await conn.query(
        "SHOW COLUMNS FROM asignaciones_agenda LIKE 'batch_id'",
      );

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
      } else {
        developer.log(
          'Columna batch_id ya existe en asignaciones_agenda, omitiendo.',
          name: 'DatabaseConnection',
        );
      }

      // Verificar si el constraint FOREIGN KEY ya existe
      final existingConstraint = await conn.query(
        "SELECT CONSTRAINT_NAME FROM information_schema.KEY_COLUMN_USAGE "
        "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'asignaciones_agenda' "
        "AND COLUMN_NAME = 'batch_id' AND REFERENCED_TABLE_NAME = 'rutina_batches'",
      );

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
      } else {
        developer.log(
          'Constraint fk_asignaciones_batch ya existe, omitiendo.',
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
          'Error asegurando el esquema de asignaciones_agenda',
          name: 'DatabaseConnection',
          error: e,
          level: 1000,
        );
        rethrow;
      }
    } catch (e, s) {
      developer.log(
        'Error inesperado asegurando el esquema de asignaciones_agenda',
        name: 'DatabaseConnection',
        error: e,
        stackTrace: s,
        level: 1000,
      );
      rethrow;
    }
  }
}
