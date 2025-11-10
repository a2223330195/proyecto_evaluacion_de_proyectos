// test/unit/screens/metricas_detalle_screen_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:coachhub/models/asesorado_metricas_activas_model.dart';

void main() {
  group('MetricasActivasIntegration', () {
    test('AsesoradoMetricasActivas - Defaults: 5 métricas activas', () {
      // ARRANGE
      final metricas = AsesoradoMetricasActivas.defaults(1);

      // ACT
      final activas = metricas.metricasActivas;
      final count = metricas.metricasActivasCount;

      // ASSERT
      expect(count, 5, reason: 'Should have 5 active metrics by default');
      expect(
        activas,
        containsAll([
          MetricaKey.peso,
          MetricaKey.imc,
          MetricaKey.porcentajeGrasa,
          MetricaKey.masaMuscular,
          MetricaKey.aguaCorporal,
        ]),
      );
      expect(activas.length, 5, reason: 'Should have exactly 5 active metrics');
    });

    test('AsesoradoMetricasActivas - Defaults: 11 métricas inactivas', () {
      // ARRANGE
      final metricas = AsesoradoMetricasActivas.defaults(1);

      // ACT
      final inactivas =
          metricas.metricas.entries
              .where((e) => !e.value)
              .map((e) => e.key)
              .toList();

      // ASSERT
      expect(inactivas.length, 11, reason: 'Should have 11 inactive metrics');
      expect(
        inactivas,
        containsAll([
          MetricaKey.pechoCm,
          MetricaKey.cinturaCm,
          MetricaKey.caderaCm,
          MetricaKey.brazoIzqCm,
          MetricaKey.brazoDerCm,
          MetricaKey.piernaIzqCm,
          MetricaKey.piernaDerCm,
          MetricaKey.pantorrillaIzqCm,
          MetricaKey.pantorrillaDerCm,
          MetricaKey.frecuenciaCardiaca,
          MetricaKey.recordResistencia,
        ]),
      );
    });

    test('AsesoradoMetricasActivas - toMap: Convierte a 1/0 para BD', () {
      // ARRANGE
      final metricas = AsesoradoMetricasActivas.defaults(42);

      // ACT
      final map = metricas.toMap();

      // ASSERT
      expect(map['asesorado_id'], 42);
      expect(map['peso_activo'], 1, reason: 'Active metrics should be 1');
      expect(map['imc_activo'], 1);
      expect(map['pecho_cm_activo'], 0, reason: 'Inactive metrics should be 0');
      expect(map['cintura_cm_activo'], 0);
    });

    test('AsesoradoMetricasActivas - copyWith: Modifica métricas', () {
      // ARRANGE
      final original = AsesoradoMetricasActivas.defaults(1);

      // ACT
      final modified = original.copyWith(
        metricas: {
          ...original.metricas,
          MetricaKey.peso: false,
          MetricaKey.pechoCm: true,
        },
      );

      // ASSERT
      expect(
        modified.metricas[MetricaKey.peso],
        false,
        reason: 'Peso should now be inactive',
      );
      expect(
        modified.metricas[MetricaKey.pechoCm],
        true,
        reason: 'Pecho should now be active',
      );
      expect(
        original.metricas[MetricaKey.peso],
        true,
        reason: 'Original should be unchanged',
      );
    });

    test('MetricaKey - displayName: Muestra etiqueta correcta', () {
      // ASSERT
      expect(MetricaKey.peso.displayName, 'Peso (kg)');
      expect(MetricaKey.imc.displayName, 'IMC');
      expect(MetricaKey.porcentajeGrasa.displayName, 'Porcentaje Grasa (%)');
      expect(MetricaKey.pechoCm.displayName, 'Pecho (cm)');
      expect(
        MetricaKey.frecuenciaCardiaca.displayName,
        'Frecuencia Cardíaca (bpm)',
      );
    });

    test('MetricaKey - columnName: Mapea a nombre de columna BD', () {
      // ASSERT
      expect(MetricaKey.peso.columnName, 'peso_activo');
      expect(MetricaKey.imc.columnName, 'imc_activo');
      expect(MetricaKey.porcentajeGrasa.columnName, 'porcentaje_grasa_activo');
      expect(MetricaKey.pechoCm.columnName, 'pecho_cm_activo');
      expect(
        MetricaKey.frecuenciaCardiaca.columnName,
        'frecuencia_cardiaca_activo',
      );
    });

    test('MetricaKey - icon: Retorna icono válido', () {
      // ACT
      final pesoIcon = MetricaKey.peso.icon;
      final imcIcon = MetricaKey.imc.icon;
      final pechIcon = MetricaKey.pechoCm.icon;

      // ASSERT
      expect(pesoIcon, isNotNull);
      expect(imcIcon, isNotNull);
      expect(pechIcon, isNotNull);
    });
  });
}
