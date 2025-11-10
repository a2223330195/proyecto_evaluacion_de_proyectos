// lib/models/rutina_model.dart

// Enum para las categorías de grupos musculares
// FASE K: Actualizado a 17 categorías basadas en ejercicios_maestro
// Nota: Los nombres sin acentos son requeridos en Dart enums
enum RutinaCategoria {
  abdominales,
  biceps, // bíceps
  triceps, // tríceps
  espalda_media,
  lats,
  espalda_baja,
  hombros,
  cuadriceps, // cuádriceps
  gluteos, // glúteos
  isquiotibiales,
  pecho,
  pantorrillas,
  antebrazos,
  trapecio,
  aductores,
  abductores,
  movilidad,
}

class Rutina {
  final int id;
  String nombre;
  String? descripcion;
  RutinaCategoria categoria;

  Rutina({
    required this.id,
    required this.nombre,
    required this.categoria,
    this.descripcion,
  });

  factory Rutina.fromMap(Map<String, dynamic> map) {
    // Convertir categoria de BD (con acentos) a enum sin acentos
    String categoriaBD = map['categoria']?.toString() ?? 'pecho';

    // Mapeo de valores de BD (con acentos) a valores de enum (sin acentos)
    final categoriasMapping = {
      'bíceps': 'biceps',
      'tríceps': 'triceps',
      'cuádriceps': 'cuadriceps',
      'glúteos': 'gluteos',
      'abdominales': 'abdominales',
      'espalda_media': 'espalda_media',
      'lats': 'lats',
      'espalda_baja': 'espalda_baja',
      'hombros': 'hombros',
      'isquiotibiales': 'isquiotibiales',
      'pecho': 'pecho',
      'pantorrillas': 'pantorrillas',
      'antebrazos': 'antebrazos',
      'trapecio': 'trapecio',
      'aductores': 'aductores',
      'abductores': 'abductores',
      'movilidad': 'movilidad',
    };

    String categoriaEnum = categoriasMapping[categoriaBD] ?? 'pecho';

    return Rutina(
      id: int.tryParse(map['id'].toString()) ?? 0,
      nombre: map['nombre']?.toString() ?? '', // Asegura que sea String
      descripcion: map['descripcion']?.toString(), // Convierte el Blob a String
      categoria: RutinaCategoria.values.firstWhere(
        (e) => e.name == categoriaEnum,
        orElse: () => RutinaCategoria.pecho, // Default a pecho si no encuentra
      ),
    );
  }
}
