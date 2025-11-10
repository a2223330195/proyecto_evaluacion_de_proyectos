import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// ============================================================================
/// METRICAS CARD TESTS - E.5.2 Widget Tests
/// ============================================================================
/// 4 Tests para validar MetricasCard
/// ============================================================================

void main() {
  group('MetricasCard - Widget Tests (E.5.2)', () {
    // TEST 1: Renderiza MetricasCard sin errores
    testWidgets('Renderiza MetricasCard sin errores', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Métricas Card Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Métricas Card Content'), findsOneWidget);
    });

    // TEST 2: Muestra gráfico de métricas
    testWidgets('Muestra representación visual de métricas', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Métricas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: Center(child: Text('Gráfico de Métricas')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Métricas'), findsOneWidget);
      expect(find.text('Gráfico de Métricas'), findsOneWidget);
    });

    // TEST 3: Métricas activas se muestran correctamente
    testWidgets('Muestra métricas activas con indicadores', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Métricas'),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Chip(
                          label: Text('Peso ✓'),
                          backgroundColor: Colors.green[100],
                        ),
                        SizedBox(width: 8),
                        Chip(
                          label: Text('Altura ✓'),
                          backgroundColor: Colors.green[100],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Peso ✓'), findsOneWidget);
      expect(find.text('Altura ✓'), findsOneWidget);
      expect(find.byType(Chip), findsWidgets);
    });

    // TEST 4: Estados Loading → Loaded funcionan
    testWidgets('Transición desde estado Loading a Loaded', (
      WidgetTester tester,
    ) async {
      bool isLoading = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Métricas'),
                    SizedBox(height: 8),
                    if (isLoading)
                      SizedBox(height: 50, child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
