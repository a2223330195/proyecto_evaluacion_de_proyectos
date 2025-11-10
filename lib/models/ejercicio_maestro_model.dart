// lib/models/ejercicio_maestro_model.dart

/// Modelo para la tabla ejercicios_maestro
/// Representa la biblioteca maestra de ejercicios con información general
class EjercicioMaestro {
  final int id;
  final String nombre;
  final String? musculoPrincipal;
  final String? equipamiento;
  final String? videoUrl;
  final String? imageUrl;
  final String? fuente;

  EjercicioMaestro({
    required this.id,
    required this.nombre,
    this.musculoPrincipal,
    this.equipamiento,
    this.videoUrl,
    this.imageUrl,
    this.fuente,
  });

  factory EjercicioMaestro.fromMap(Map<String, dynamic> map) {
    return EjercicioMaestro(
      id: int.tryParse(map['id'].toString()) ?? 0,
      nombre: map['nombre']?.toString() ?? '',
      musculoPrincipal: map['musculo_principal']?.toString(),
      equipamiento: map['equipamiento']?.toString(),
      videoUrl: map['video_url']?.toString(),
      imageUrl: map['image_url']?.toString(),
      fuente: map['fuente']?.toString() ?? 'workout.cool',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'musculo_principal': musculoPrincipal,
      'equipamiento': equipamiento,
      'video_url': videoUrl,
      'image_url': imageUrl,
      'fuente': fuente,
    };
  }

  EjercicioMaestro copyWith({
    int? id,
    String? nombre,
    String? musculoPrincipal,
    String? equipamiento,
    String? videoUrl,
    String? imageUrl,
    String? fuente,
  }) {
    return EjercicioMaestro(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      musculoPrincipal: musculoPrincipal ?? this.musculoPrincipal,
      equipamiento: equipamiento ?? this.equipamiento,
      videoUrl: videoUrl ?? this.videoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      fuente: fuente ?? this.fuente,
    );
  }

  @override
  String toString() =>
      'EjercicioMaestro(id: $id, nombre: $nombre, musculo: $musculoPrincipal, equipo: $equipamiento)';
}
