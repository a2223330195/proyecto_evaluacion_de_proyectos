import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

double? _parseDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

/// Clase que representa una métrica con su etiqueta, valor, unidad e ícono
class MetricaDisplay {
  final String label;
  final String value;
  final String unit;
  final IconData? icon;

  const MetricaDisplay({
    required this.label,
    required this.value,
    required this.unit,
    this.icon,
  });

  String get displayValue => unit.isEmpty ? value : '$value $unit';
}

class Medicion {
  final int id;
  final int asesoradoId;
  final DateTime fechaMedicion;
  final double? peso;
  final double? porcentajeGrasa;
  final double? imc;
  final double? masaMuscular;
  final double? aguaCorporal;
  final double? pechoCm;
  final double? cinturaCm;
  final double? caderaCm;
  final double? brazoIzqCm;
  final double? brazoDerCm;
  final double? piernaIzqCm;
  final double? piernaDerCm;
  final double? pantorrillaIzqCm;
  final double? pantorrillaDerCm;
  final double? frecuenciaCardiaca;
  final double? recordResistencia;
  final DateTime? createdAt;

  const Medicion({
    required this.id,
    required this.asesoradoId,
    required this.fechaMedicion,
    this.peso,
    this.porcentajeGrasa,
    this.imc,
    this.masaMuscular,
    this.aguaCorporal,
    this.pechoCm,
    this.cinturaCm,
    this.caderaCm,
    this.brazoIzqCm,
    this.brazoDerCm,
    this.piernaIzqCm,
    this.piernaDerCm,
    this.pantorrillaIzqCm,
    this.pantorrillaDerCm,
    this.frecuenciaCardiaca,
    this.recordResistencia,
    this.createdAt,
  });

  factory Medicion.fromMap(Map<String, dynamic> map) {
    return Medicion(
      id: int.tryParse(map['id'].toString()) ?? 0,
      asesoradoId: int.tryParse(map['asesorado_id'].toString()) ?? 0,
      fechaMedicion:
          map['fecha_medicion'] == null
              ? DateTime(1970, 1, 1)
              : DateTime.parse(map['fecha_medicion'].toString()),
      peso: _parseDouble(map['peso']),
      porcentajeGrasa: _parseDouble(map['porcentaje_grasa']),
      imc: _parseDouble(map['imc']),
      masaMuscular: _parseDouble(map['masa_muscular']),
      aguaCorporal: _parseDouble(map['agua_corporal']),
      pechoCm: _parseDouble(map['pecho_cm']),
      cinturaCm: _parseDouble(map['cintura_cm']),
      caderaCm: _parseDouble(map['cadera_cm']),
      brazoIzqCm: _parseDouble(map['brazo_izq_cm']),
      brazoDerCm: _parseDouble(map['brazo_der_cm']),
      piernaIzqCm: _parseDouble(map['pierna_izq_cm']),
      piernaDerCm: _parseDouble(map['pierna_der_cm']),
      pantorrillaIzqCm: _parseDouble(map['pantorrilla_izq_cm']),
      pantorrillaDerCm: _parseDouble(map['pantorrilla_der_cm']),
      frecuenciaCardiaca: _parseDouble(map['frecuencia_cardiaca']),
      recordResistencia: _parseDouble(map['record_resistencia']),
      createdAt:
          map['created_at'] == null
              ? null
              : DateTime.tryParse(map['created_at'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asesorado_id': asesoradoId,
      'fecha_medicion': fechaMedicion.toIso8601String(),
      'peso': peso,
      'porcentaje_grasa': porcentajeGrasa,
      'imc': imc,
      'masa_muscular': masaMuscular,
      'agua_corporal': aguaCorporal,
      'pecho_cm': pechoCm,
      'cintura_cm': cinturaCm,
      'cadera_cm': caderaCm,
      'brazo_izq_cm': brazoIzqCm,
      'brazo_der_cm': brazoDerCm,
      'pierna_izq_cm': piernaIzqCm,
      'pierna_der_cm': piernaDerCm,
      'pantorrilla_izq_cm': pantorrillaIzqCm,
      'pantorrilla_der_cm': pantorrillaDerCm,
      'frecuencia_cardiaca': frecuenciaCardiaca,
      'record_resistencia': recordResistencia,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Map<String, String> toReadableMap() {
    final Map<String, String> data = {
      'Fecha de medición': DateFormat('dd/MM/yyyy').format(fechaMedicion),
    };

    void addIfNotNull(String label, double? value, {String unit = ''}) {
      if (value != null) {
        final formatted =
            value == value.roundToDouble()
                ? value.toStringAsFixed(0)
                : value.toStringAsFixed(1);
        data[label] = unit.isEmpty ? formatted : '$formatted $unit';
      }
    }

    addIfNotNull('Peso', peso, unit: 'kg');
    addIfNotNull('Porcentaje de grasa', porcentajeGrasa, unit: '%');
    addIfNotNull('IMC', imc);
    addIfNotNull('Masa muscular', masaMuscular, unit: 'kg');
    addIfNotNull('Agua corporal', aguaCorporal, unit: '%');
    addIfNotNull('Pecho', pechoCm, unit: 'cm');
    addIfNotNull('Cintura', cinturaCm, unit: 'cm');
    addIfNotNull('Cadera', caderaCm, unit: 'cm');
    addIfNotNull('Brazo izquierdo', brazoIzqCm, unit: 'cm');
    addIfNotNull('Brazo derecho', brazoDerCm, unit: 'cm');
    addIfNotNull('Pierna izquierda', piernaIzqCm, unit: 'cm');
    addIfNotNull('Pierna derecha', piernaDerCm, unit: 'cm');
    addIfNotNull('Pantorrilla izquierda', pantorrillaIzqCm, unit: 'cm');
    addIfNotNull('Pantorrilla derecha', pantorrillaDerCm, unit: 'cm');
    addIfNotNull('Frecuencia cardiaca', frecuenciaCardiaca, unit: 'bpm');
    addIfNotNull('Record resistencia', recordResistencia, unit: 's');

    return data;
  }

  /// Retorna lista de métricas con sus iconos para la tarjeta (sin fecha)
  List<MetricaDisplay> toMetricasDisplay() {
    final List<MetricaDisplay> metricas = [];

    void addIfNotNull(
      String label,
      double? value, {
      String unit = '',
      IconData? icon,
    }) {
      if (value != null) {
        final formatted =
            value == value.roundToDouble()
                ? value.toStringAsFixed(0)
                : value.toStringAsFixed(1);
        metricas.add(
          MetricaDisplay(
            label: label,
            value: formatted,
            unit: unit,
            icon: icon,
          ),
        );
      }
    }

    addIfNotNull('Peso', peso, unit: 'kg', icon: Icons.monitor_weight_outlined);
    addIfNotNull('Grasa', porcentajeGrasa, unit: '%', icon: Icons.percent);
    addIfNotNull('IMC', imc, icon: Icons.health_and_safety_outlined);
    addIfNotNull(
      'Masa muscular',
      masaMuscular,
      unit: 'kg',
      icon: Icons.fitness_center,
    );
    addIfNotNull('Agua corporal', aguaCorporal, unit: '%', icon: Icons.opacity);
    addIfNotNull('Pecho', pechoCm, unit: 'cm', icon: Icons.straighten);
    addIfNotNull('Cintura', cinturaCm, unit: 'cm', icon: Icons.rule);
    addIfNotNull('Cadera', caderaCm, unit: 'cm', icon: Icons.straighten);
    addIfNotNull(
      'Brazo izq.',
      brazoIzqCm,
      unit: 'cm',
      icon: Icons.accessibility_new,
    );
    addIfNotNull(
      'Brazo der.',
      brazoDerCm,
      unit: 'cm',
      icon: Icons.accessibility_new,
    );
    addIfNotNull(
      'Pierna izq.',
      piernaIzqCm,
      unit: 'cm',
      icon: Icons.directions_walk,
    );
    addIfNotNull(
      'Pierna der.',
      piernaDerCm,
      unit: 'cm',
      icon: Icons.directions_walk,
    );
    addIfNotNull(
      'Pantorrilla izq.',
      pantorrillaIzqCm,
      unit: 'cm',
      icon: Icons.directions_run,
    );
    addIfNotNull(
      'Pantorrilla der.',
      pantorrillaDerCm,
      unit: 'cm',
      icon: Icons.directions_run,
    );
    addIfNotNull(
      'Frec. cardiaca',
      frecuenciaCardiaca,
      unit: 'bpm',
      icon: Icons.favorite_outline,
    );
    addIfNotNull(
      'Record resistencia',
      recordResistencia,
      unit: 's',
      icon: Icons.timer_outlined,
    );

    return metricas;
  }
}
