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
    String categoriaBD = map['categoria']?.toString() ?? '';

    // Mapeo bidireccional de valores de BD (con y sin acentos) a valores de enum
    // Incluye variantes con y sin acentos para compatibilidad con datos persistidos
    final categoriasMapping = {
      // Variantes con acentos
      'bíceps': 'biceps',
      'tríceps': 'triceps',
      'cuádriceps': 'cuadriceps',
      'glúteos': 'gluteos',
      // Variantes sin acentos (guardadas por _categoria.name)
      'biceps': 'biceps',
      'triceps': 'triceps',
      'cuadriceps': 'cuadriceps',
      'gluteos': 'gluteos',
      // Todas las demás categorías (con y sin acentos, donde sea aplicable)
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

    // Buscar valor en mapeo; si no existe, intentar sin acentos
    String categoriaEnum = categoriasMapping[categoriaBD] ?? categoriaBD;

    // Si aún no encuentra, retornar abdominales como default neutro (no pecho)
    if (!RutinaCategoria.values.any((e) => e.name == categoriaEnum)) {
      categoriaEnum = 'abdominales';
    }

    return Rutina(
      id: int.tryParse(map['id'].toString()) ?? 0,
      nombre: map['nombre']?.toString() ?? '', // Asegura que sea String
      descripcion: map['descripcion']?.toString(), // Convierte el Blob a String
      categoria: RutinaCategoria.values.firstWhere(
        (e) => e.name == categoriaEnum,
        orElse:
            () =>
                RutinaCategoria
                    .abdominales, // Default a abdominales (más neutro)
      ),
    );
  }
}
