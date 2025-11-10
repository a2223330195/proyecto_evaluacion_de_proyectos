class PlanNutricional {
  final int id;
  final int asesoradoId;
  final String nombrePlan;
  final int? caloriasDiarias;
  final int? proteinasGr;
  final int? grasasGr;
  final int? carbosGr;
  final String? recomendaciones;

  PlanNutricional({
    required this.id,
    required this.asesoradoId,
    required this.nombrePlan,
    this.caloriasDiarias,
    this.proteinasGr,
    this.grasasGr,
    this.carbosGr,
    this.recomendaciones,
  });

  factory PlanNutricional.fromMap(Map<String, dynamic> map) {
    return PlanNutricional(
      id: int.tryParse(map['id'].toString()) ?? 0,
      asesoradoId: int.tryParse(map['asesorado_id'].toString()) ?? 0,
      nombrePlan: map['nombre_plan']?.toString() ?? '',
      caloriasDiarias:
          map['calorias_diarias'] != null
              ? int.tryParse(map['calorias_diarias'].toString())
              : null,
      proteinasGr:
          map['proteinas_gr'] != null
              ? int.tryParse(map['proteinas_gr'].toString())
              : null,
      grasasGr:
          map['grasas_gr'] != null
              ? int.tryParse(map['grasas_gr'].toString())
              : null,
      carbosGr:
          map['carbos_gr'] != null
              ? int.tryParse(map['carbos_gr'].toString())
              : null,

      // --- CORRECCIÓN YA APLICADA AQUÍ ---
      recomendaciones: map['recomendaciones']?.toString(),
      // --- FIN DE LA CORRECCIÓN ---
    );
  }
}
