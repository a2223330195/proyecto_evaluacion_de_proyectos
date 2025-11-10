// lib/models/coach_model.dart

class Coach {
  final int id;
  final String nombre;
  final String email;
  final String plan;
  final String? profilePictureUrl;

  Coach({
    required this.id,
    required this.nombre,
    required this.email,
    required this.plan,
    this.profilePictureUrl,
  });

  factory Coach.fromMap(Map<String, dynamic> map) {
    return Coach(
      id: int.tryParse(map['id'].toString()) ?? 0,
      nombre: map['nombre'].toString(),
      email: map['email'].toString(),
      plan: map['plan'].toString(),
      profilePictureUrl: map['profile_picture_url'] as String?,
    );
  }
}
