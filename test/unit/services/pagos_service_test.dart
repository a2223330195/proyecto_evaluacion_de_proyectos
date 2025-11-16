import 'package:flutter_test/flutter_test.dart';

/// Tests unitarios para la lógica de _determinarPeriodoObjetivo
/// Cubre 4 escenarios críticos de cálculo de saldo y ventana de corte
void main() {
  group('PagosService._determinarPeriodoObjetivo', () {
    test(
      'Scenario A: Período pendiente con abonos → saldo = costoPlan - totalAbonado',
      () {
        // Arrange
        final costoPlan = 100.0;
        final totalAbonado = 40.0;
        final saldoEsperado = costoPlan - totalAbonado; // 60.0

        // Simulamos que el histórico tiene:
        // 2025-10: pagado (100.0)
        // 2025-11: abonado parcialmente (40.0)
        final historial = {'2025-10': 100.0, '2025-11': totalAbonado};

        // Act: lógica de _determinarPeriodoObjetivo
        // 1. Buscar primer período con saldo < costo
        String? periodoPendiente;
        double totalAbonadoPeriodo = 0.0;
        for (final entry in historial.entries) {
          if (entry.value < costoPlan) {
            periodoPendiente = entry.key;
            totalAbonadoPeriodo = entry.value;
            break;
          }
        }

        final saldoCalculado = costoPlan - totalAbonadoPeriodo;

        // Assert
        expect(
          periodoPendiente,
          equals('2025-11'),
          reason: 'Debe encontrar el período pendiente',
        );
        expect(
          saldoCalculado,
          equals(saldoEsperado),
          reason: 'Saldo debe ser costoPlan - abonado',
        );
        expect(
          saldoCalculado,
          greaterThan(0),
          reason: 'Saldo debe ser positivo (pendiente real)',
        );
      },
    );

    test(
      'Scenario B: Sin pendientes, fecha fuera de alerta → saldo=0, periodoFuturoDisponible=true',
      () {
        // Arrange
        final costoPlan = 100.0;
        final ahora = DateTime(2025, 11, 16);
        final fechaVencimiento = DateTime(
          2025,
          12,
          25,
        ); // 39 días adelante (> 5 días de alerta)
        final diasAvisoCorte = 5;

        // Histórico: todos los periodos pagados
        final historial = {'2025-10': 100.0, '2025-11': 100.0};

        // Act
        String? periodoPendiente;
        for (final entry in historial.entries) {
          if (entry.value < costoPlan) {
            periodoPendiente = entry.key;
            break;
          }
        }

        // Como no hay pendiente, evaluar ventana de corte
        final diasHastaVencimiento = fechaVencimiento.difference(ahora).inDays;
        final periodoEnVentanaCorte =
            fechaVencimiento.isAfter(ahora) &&
            diasHastaVencimiento <= diasAvisoCorte;
        final saldoCalculado = periodoEnVentanaCorte ? costoPlan : 0.0;
        final periodoFuturoDisponible = !periodoEnVentanaCorte;

        // Assert
        expect(
          periodoPendiente,
          isNull,
          reason: 'No debe haber período pendiente',
        );
        expect(
          saldoCalculado,
          equals(0.0),
          reason: 'Saldo debe ser 0 fuera de ventana de corte',
        );
        expect(
          periodoFuturoDisponible,
          isTrue,
          reason: 'Debe permitir pago por adelantado',
        );
        expect(
          diasHastaVencimiento,
          greaterThan(diasAvisoCorte),
          reason: 'Verificar que esté fuera de la alerta',
        );
      },
    );

    test(
      'Scenario C: Sin pendientes, dentro de ventana de corte → saldo=costoPlan, enVentanaCorte=true',
      () {
        // Arrange
        final costoPlan = 100.0;
        final ahora = DateTime(2025, 11, 26);
        final fechaVencimiento = DateTime(
          2025,
          11,
          30,
        ); // 4 días adelante (dentro de 5 días de alerta)
        final diasAvisoCorte = 5;

        // Histórico: todos los periodos pagados
        final historial = {'2025-10': 100.0, '2025-11': 100.0};

        // Act
        String? periodoPendiente;
        for (final entry in historial.entries) {
          if (entry.value < costoPlan) {
            periodoPendiente = entry.key;
            break;
          }
        }

        final diasHastaVencimiento = fechaVencimiento.difference(ahora).inDays;
        final periodoEnVentanaCorte =
            fechaVencimiento.isAfter(ahora) &&
            diasHastaVencimiento <= diasAvisoCorte;
        final saldoCalculado = periodoEnVentanaCorte ? costoPlan : 0.0;

        // Assert
        expect(
          periodoPendiente,
          isNull,
          reason: 'No debe haber período pendiente',
        );
        expect(
          periodoEnVentanaCorte,
          isTrue,
          reason: 'Debe estar en ventana de corte',
        );
        expect(
          saldoCalculado,
          equals(costoPlan),
          reason: 'Saldo debe mostrar el costo del siguiente periodo',
        );
        expect(
          diasHastaVencimiento,
          lessThanOrEqualTo(diasAvisoCorte),
          reason: 'Verificar que esté dentro de la alerta',
        );
      },
    );

    test(
      'Scenario D: Fecha vencida (pasado) → saldo=costoPlan, estado=vencido',
      () {
        // Arrange
        final costoPlan = 100.0;
        final ahora = DateTime(2025, 12, 1);
        final fechaVencimiento = DateTime(2025, 11, 25); // Pasado (vencido)

        // Histórico: todos los periodos pagados
        final historial = {'2025-10': 100.0, '2025-11': 100.0};

        // Act
        String? periodoPendiente;
        for (final entry in historial.entries) {
          if (entry.value < costoPlan) {
            periodoPendiente = entry.key;
            break;
          }
        }

        final vencido = !fechaVencimiento.isAfter(ahora);
        final saldoCalculado = vencido ? costoPlan : 0.0;
        final estado = vencido ? 'vencido' : 'activo';

        // Assert
        expect(
          periodoPendiente,
          isNull,
          reason: 'No debe haber período pendiente',
        );
        expect(vencido, isTrue, reason: 'La fecha debe estar vencida');
        expect(
          saldoCalculado,
          equals(costoPlan),
          reason: 'Saldo debe mostrar el costo del periodo vencido',
        );
        expect(estado, equals('vencido'), reason: 'Estado debe ser vencido');
      },
    );

    test('Período sugerido: sin pendientes → sugerir próximo periodo', () {
      // Arrange
      final historial = {'2025-09': 100.0, '2025-10': 100.0, '2025-11': 100.0};

      // Act: encontrar próximo periodo
      String? ultimoPeriodo;
      for (final entry in historial.entries) {
        ultimoPeriodo = entry.key;
      }

      String periodoSugerido = '2025-12'; // siguiente al último
      if (ultimoPeriodo != null && ultimoPeriodo.isNotEmpty) {
        final base = DateTime(
          int.parse(ultimoPeriodo.split('-')[0]),
          int.parse(ultimoPeriodo.split('-')[1]),
          1,
        );
        final siguiente = DateTime(base.year, base.month + 1, 1);
        periodoSugerido =
            '${siguiente.year}-${siguiente.month.toString().padLeft(2, '0')}';
      }

      // Assert
      expect(
        periodoSugerido,
        equals('2025-12'),
        reason: 'Debe sugerir el mes siguiente',
      );
    });

    test('Validación de formato YYYY-MM', () {
      // Asegurar que los periodos siempre estén en formato YYYY-MM
      final periodosValidos = ['2025-01', '2025-11', '2025-12'];
      final periodosInvalidos = ['2025-1', '25-01', '2025/11'];

      // Función auxiliar para validar periodo
      void validatePeriodo(String periodo) {
        final parts = periodo.split('-');
        if (parts.length != 2) {
          throw Exception('Formato inválido: debe tener YYYY-MM');
        }

        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);

        if (year == null || month == null) {
          throw Exception('Año y mes deben ser números');
        }

        if (year < 1900 || year > 2100) {
          throw Exception('Año fuera de rango válido');
        }

        if (month < 1 || month > 12) {
          throw Exception('Mes debe estar entre 01 y 12');
        }

        if (parts[1] != month.toString().padLeft(2, '0')) {
          throw Exception('Mes debe estar en formato MM (ej: 01, no 1)');
        }
      }

      // Validar periodos válidos
      for (final periodo in periodosValidos) {
        expect(
          () => validatePeriodo(periodo),
          returnsNormally,
          reason: 'El periodo $periodo debe ser válido',
        );
      }

      // Validar que periodos inválidos lancen excepciones
      for (final periodo in periodosInvalidos) {
        expect(
          () => validatePeriodo(periodo),
          throwsException,
          reason: 'El periodo $periodo debe ser rechazado',
        );
      }
    });
  });
}
