// lib/models/ejercicio_model.dart

import 'package:coachhub/models/ejercicio_maestro_model.dart';

/// Modelo para la tabla ejercicios
/// Representa un ejercicio dentro de una plantilla de rutina
/// Ahora hace referencia a la tabla ejercicios_maestro
///
/// NOTA: series, repeticiones, indicadorCarga son String? para permitir flexibilidad
/// Ejemplos: "8-12", "Al fallo", "RPE 8", "50kg", etc.
class Ejercicio {
  final int id;
  final int plantillaId;
  final int ejercicioMaestroId;
  final String? series; // Ej: "3", "3-4", "Al fallo"
  final String? repeticiones; // Ej: "8", "8-12", "Máximas"
  final String? indicadorCarga; // Ej: "50kg", "RPE 8", "80% 1RM"
  final String? descanso;
  final String? notas;
  final int orden;

  /// Campo extra (no en BD): Detalles del ejercicio maestro obtenidos del JOIN
  final EjercicioMaestro? detalleMaestro;

  /// Campo temporal para la UI durante creación/edición (se sincroniza con detalleMaestro.nombre)
  String? nombre;

  Ejercicio({
    this.id = 0,
    this.plantillaId = 0,
    this.ejercicioMaestroId = 0,
    this.series,
    this.repeticiones,
    this.indicadorCarga,
    this.descanso,
    this.notas,
    this.orden = 0,
    this.detalleMaestro,
    this.nombre,
  });

  factory Ejercicio.fromMap(Map<String, dynamic> map) {
    // Construir el objeto detalleMaestro si están presentes los campos del JOIN
    EjercicioMaestro? detalle;
    String? nombreTemp;

    if (map.containsKey('nombre') && map['nombre'] != null) {
      nombreTemp = map['nombre'].toString();
      detalle = EjercicioMaestro(
        id: int.tryParse(map['ejercicio_maestro_id'].toString()) ?? 0,
        nombre: nombreTemp,
        musculoPrincipal: map['musculo_principal']?.toString(),
        equipamiento: map['equipamiento']?.toString(),
        videoUrl: map['video_url']?.toString(),
        fuente: map['fuente']?.toString() ?? 'workout.cool',
      );
    }

    final ejercicio = Ejercicio(
      id: int.tryParse(map['id'].toString()) ?? 0,
      plantillaId: int.tryParse(map['plantilla_id'].toString()) ?? 0,
      ejercicioMaestroId:
          int.tryParse(map['ejercicio_maestro_id'].toString()) ?? 0,
      series: map['series']?.toString(),
      repeticiones: map['repeticiones']?.toString(),
      indicadorCarga:
          map['indicador_carga']?.toString() ??
          map['peso']?.toString(), // Fallback a 'peso' para compatibilidad
      descanso: map['descanso']?.toString(),
      notas: map['notas']?.toString(),
      orden: int.tryParse(map['orden'].toString()) ?? 0,
      detalleMaestro: detalle,
    );

    // Sincronizar nombre desde detalleMaestro
    ejercicio.nombre = nombreTemp ?? detalle?.nombre;

    return ejercicio;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plantilla_id': plantillaId,
      'ejercicio_maestro_id': ejercicioMaestroId,
      'series': series,
      'repeticiones': repeticiones,
      'indicador_carga': indicadorCarga,
      'descanso': descanso,
      'notas': notas,
      'orden': orden,
    };
  }

  Ejercicio copyWith({
    int? id,
    int? plantillaId,
    int? ejercicioMaestroId,
    String? series,
    String? repeticiones,
    String? indicadorCarga,
    String? descanso,
    String? notas,
    int? orden,
    EjercicioMaestro? detalleMaestro,
    String? nombre,
  }) {
    final copied = Ejercicio(
      id: id ?? this.id,
      plantillaId: plantillaId ?? this.plantillaId,
      ejercicioMaestroId: ejercicioMaestroId ?? this.ejercicioMaestroId,
      series: series ?? this.series,
      repeticiones: repeticiones ?? this.repeticiones,
      indicadorCarga: indicadorCarga ?? this.indicadorCarga,
      descanso: descanso ?? this.descanso,
      notas: notas ?? this.notas,
      orden: orden ?? this.orden,
      detalleMaestro: detalleMaestro ?? this.detalleMaestro,
    );
    copied.nombre = nombre ?? this.nombre;
    return copied;
  }

  @override
  String toString() =>
      'Ejercicio(id: $id, maestroId: $ejercicioMaestroId, nombre: ${detalleMaestro?.nombre}, series: $series, reps: $repeticiones, carga: $indicadorCarga)';
}
