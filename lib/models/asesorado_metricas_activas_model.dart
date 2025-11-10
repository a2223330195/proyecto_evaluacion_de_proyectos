// lib/models/asesorado_metricas_activas_model.dart

import 'package:flutter/material.dart';

/// Enumeración de todas las métricas que pueden ser activas/inactivas
enum MetricaKey {
  peso,
  imc,
  porcentajeGrasa,
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
}

/// Extensión para convertir enum a nombre de columna BD
extension MetricaKeyExtension on MetricaKey {
  String get columnName {
    switch (this) {
      case MetricaKey.peso:
        return 'peso_activo';
      case MetricaKey.imc:
        return 'imc_activo';
      case MetricaKey.porcentajeGrasa:
        return 'porcentaje_grasa_activo';
      case MetricaKey.masaMuscular:
        return 'masa_muscular_activo';
      case MetricaKey.aguaCorporal:
        return 'agua_corporal_activo';
      case MetricaKey.pechoCm:
        return 'pecho_cm_activo';
      case MetricaKey.cinturaCm:
        return 'cintura_cm_activo';
      case MetricaKey.caderaCm:
        return 'cadera_cm_activo';
      case MetricaKey.brazoIzqCm:
        return 'brazo_izq_cm_activo';
      case MetricaKey.brazoDerCm:
        return 'brazo_der_cm_activo';
      case MetricaKey.piernaIzqCm:
        return 'pierna_izq_cm_activo';
      case MetricaKey.piernaDerCm:
        return 'pierna_der_cm_activo';
      case MetricaKey.pantorrillaIzqCm:
        return 'pantorrilla_izq_cm_activo';
      case MetricaKey.pantorrillaDerCm:
        return 'pantorrilla_der_cm_activo';
      case MetricaKey.frecuenciaCardiaca:
        return 'frecuencia_cardiaca_activo';
      case MetricaKey.recordResistencia:
        return 'record_resistencia_activo';
    }
  }

  String get displayName {
    switch (this) {
      case MetricaKey.peso:
        return 'Peso (kg)';
      case MetricaKey.imc:
        return 'IMC';
      case MetricaKey.porcentajeGrasa:
        return 'Grasa corporal (%)';
      case MetricaKey.masaMuscular:
        return 'Masa muscular (kg)';
      case MetricaKey.aguaCorporal:
        return 'Agua corporal (%)';
      case MetricaKey.pechoCm:
        return 'Pecho (cm)';
      case MetricaKey.cinturaCm:
        return 'Cintura (cm)';
      case MetricaKey.caderaCm:
        return 'Cadera (cm)';
      case MetricaKey.brazoIzqCm:
        return 'Brazo izquierdo (cm)';
      case MetricaKey.brazoDerCm:
        return 'Brazo derecho (cm)';
      case MetricaKey.piernaIzqCm:
        return 'Pierna izquierda (cm)';
      case MetricaKey.piernaDerCm:
        return 'Pierna derecha (cm)';
      case MetricaKey.pantorrillaIzqCm:
        return 'Pantorrilla izquierda (cm)';
      case MetricaKey.pantorrillaDerCm:
        return 'Pantorrilla derecha (cm)';
      case MetricaKey.frecuenciaCardiaca:
        return 'Frecuencia cardiaca (bpm)';
      case MetricaKey.recordResistencia:
        return 'Record resistencia (s)';
    }
  }

  IconData get icon {
    switch (this) {
      case MetricaKey.peso:
        return Icons.monitor_weight_outlined;
      case MetricaKey.imc:
        return Icons.health_and_safety_outlined;
      case MetricaKey.porcentajeGrasa:
        return Icons.percent;
      case MetricaKey.masaMuscular:
        return Icons.fitness_center;
      case MetricaKey.aguaCorporal:
        return Icons.opacity;
      case MetricaKey.pechoCm:
      case MetricaKey.cinturaCm:
      case MetricaKey.caderaCm:
        return Icons.straighten;
      case MetricaKey.brazoIzqCm:
      case MetricaKey.brazoDerCm:
      case MetricaKey.piernaIzqCm:
      case MetricaKey.piernaDerCm:
        return Icons.accessibility_new;
      case MetricaKey.pantorrillaIzqCm:
      case MetricaKey.pantorrillaDerCm:
        return Icons.directions_run;
      case MetricaKey.frecuenciaCardiaca:
        return Icons.favorite_outline;
      case MetricaKey.recordResistencia:
        return Icons.timer_outlined;
    }
  }
}

/// Modelo para configuración de métricas activas por asesorado
/// Define qué métricas el coach desea rastrear para cada asesorado
class AsesoradoMetricasActivas {
  final int id;
  final int asesoradoId;
  final Map<MetricaKey, bool> metricas;
  final DateTime createdAt;
  final DateTime updatedAt;

  AsesoradoMetricasActivas({
    required this.id,
    required this.asesoradoId,
    required this.metricas,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convertir desde Map de BD
  factory AsesoradoMetricasActivas.fromMap(Map<String, dynamic> map) {
    return AsesoradoMetricasActivas(
      id: int.tryParse(map['id'].toString()) ?? 0,
      asesoradoId: int.tryParse(map['asesorado_id'].toString()) ?? 0,
      metricas: {
        MetricaKey.peso: (map['peso_activo'] ?? 1) == 1,
        MetricaKey.imc: (map['imc_activo'] ?? 1) == 1,
        MetricaKey.porcentajeGrasa: (map['porcentaje_grasa_activo'] ?? 1) == 1,
        MetricaKey.masaMuscular: (map['masa_muscular_activo'] ?? 1) == 1,
        MetricaKey.aguaCorporal: (map['agua_corporal_activo'] ?? 1) == 1,
        MetricaKey.pechoCm: (map['pecho_cm_activo'] ?? 0) == 1,
        MetricaKey.cinturaCm: (map['cintura_cm_activo'] ?? 0) == 1,
        MetricaKey.caderaCm: (map['cadera_cm_activo'] ?? 0) == 1,
        MetricaKey.brazoIzqCm: (map['brazo_izq_cm_activo'] ?? 0) == 1,
        MetricaKey.brazoDerCm: (map['brazo_der_cm_activo'] ?? 0) == 1,
        MetricaKey.piernaIzqCm: (map['pierna_izq_cm_activo'] ?? 0) == 1,
        MetricaKey.piernaDerCm: (map['pierna_der_cm_activo'] ?? 0) == 1,
        MetricaKey.pantorrillaIzqCm:
            (map['pantorrilla_izq_cm_activo'] ?? 0) == 1,
        MetricaKey.pantorrillaDerCm:
            (map['pantorrilla_der_cm_activo'] ?? 0) == 1,
        MetricaKey.frecuenciaCardiaca:
            (map['frecuencia_cardiaca_activo'] ?? 0) == 1,
        MetricaKey.recordResistencia:
            (map['record_resistencia_activo'] ?? 0) == 1,
      },
      createdAt:
          DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now(),
    );
  }

  /// Convertir a Map para BD
  Map<String, dynamic> toMap() {
    return {
      'asesorado_id': asesoradoId,
      'peso_activo': (metricas[MetricaKey.peso] ?? false) ? 1 : 0,
      'imc_activo': (metricas[MetricaKey.imc] ?? false) ? 1 : 0,
      'porcentaje_grasa_activo':
          (metricas[MetricaKey.porcentajeGrasa] ?? false) ? 1 : 0,
      'masa_muscular_activo':
          (metricas[MetricaKey.masaMuscular] ?? false) ? 1 : 0,
      'agua_corporal_activo':
          (metricas[MetricaKey.aguaCorporal] ?? false) ? 1 : 0,
      'pecho_cm_activo': (metricas[MetricaKey.pechoCm] ?? false) ? 1 : 0,
      'cintura_cm_activo': (metricas[MetricaKey.cinturaCm] ?? false) ? 1 : 0,
      'cadera_cm_activo': (metricas[MetricaKey.caderaCm] ?? false) ? 1 : 0,
      'brazo_izq_cm_activo': (metricas[MetricaKey.brazoIzqCm] ?? false) ? 1 : 0,
      'brazo_der_cm_activo': (metricas[MetricaKey.brazoDerCm] ?? false) ? 1 : 0,
      'pierna_izq_cm_activo':
          (metricas[MetricaKey.piernaIzqCm] ?? false) ? 1 : 0,
      'pierna_der_cm_activo':
          (metricas[MetricaKey.piernaDerCm] ?? false) ? 1 : 0,
      'pantorrilla_izq_cm_activo':
          (metricas[MetricaKey.pantorrillaIzqCm] ?? false) ? 1 : 0,
      'pantorrilla_der_cm_activo':
          (metricas[MetricaKey.pantorrillaDerCm] ?? false) ? 1 : 0,
      'frecuencia_cardiaca_activo':
          (metricas[MetricaKey.frecuenciaCardiaca] ?? false) ? 1 : 0,
      'record_resistencia_activo':
          (metricas[MetricaKey.recordResistencia] ?? false) ? 1 : 0,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Retornar defaults para nuevo asesorado
  static AsesoradoMetricasActivas defaults(int asesoradoId) {
    return AsesoradoMetricasActivas(
      id: 0,
      asesoradoId: asesoradoId,
      metricas: {
        MetricaKey.peso: true,
        MetricaKey.imc: true,
        MetricaKey.porcentajeGrasa: true,
        MetricaKey.masaMuscular: true,
        MetricaKey.aguaCorporal: true,
        MetricaKey.pechoCm: false,
        MetricaKey.cinturaCm: false,
        MetricaKey.caderaCm: false,
        MetricaKey.brazoIzqCm: false,
        MetricaKey.brazoDerCm: false,
        MetricaKey.piernaIzqCm: false,
        MetricaKey.piernaDerCm: false,
        MetricaKey.pantorrillaIzqCm: false,
        MetricaKey.pantorrillaDerCm: false,
        MetricaKey.frecuenciaCardiaca: false,
        MetricaKey.recordResistencia: false,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Contar cuántas métricas están activas
  int get metricasActivasCount {
    return metricas.values.where((v) => v).length;
  }

  /// Obtener lista de métricas activas
  List<MetricaKey> get metricasActivas {
    return metricas.entries.where((e) => e.value).map((e) => e.key).toList();
  }

  /// Copiar con nuevas métricas
  AsesoradoMetricasActivas copyWith({Map<MetricaKey, bool>? metricas}) {
    return AsesoradoMetricasActivas(
      id: id,
      asesoradoId: asesoradoId,
      metricas: metricas ?? this.metricas,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'AsesoradoMetricasActivas(asesoradoId: $asesoradoId, activas: $metricasActivasCount)';
  }
}
