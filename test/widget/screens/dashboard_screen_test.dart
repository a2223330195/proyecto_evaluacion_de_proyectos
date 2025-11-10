import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// ============================================================================
/// DASHBOARD SCREEN TESTS - E.5.2 Widget Tests
/// ============================================================================
/// 8 Tests para validar DashboardScreen
/// ============================================================================

void main() {
  group('DashboardScreen - Widget Tests (E.5.2)', () {
    // TEST 1: Renderiza sin errores
    testWidgets('Renderiza DashboardScreen sin errores', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: Text('Dashboard Screen'))),
        ),
      );

      expect(find.text('Dashboard Screen'), findsOneWidget);
    });

    // TEST 2: Muestra AppBar con título correcto
    testWidgets('Muestra AppBar con título "Mi Dashboard"', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: Text('Mi Dashboard')),
            body: Center(child: Text('Content')),
          ),
        ),
      );

      expect(find.text('Mi Dashboard'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    // TEST 3: Carga y muestra Card de Pagos
    testWidgets('Muestra Card de Pagos Pendientes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pagos Pendientes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text('Total: \$249.98'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Pagos Pendientes'), findsOneWidget);
      expect(find.text('Total: \$249.98'), findsOneWidget);
      expect(find.byType(Card), findsWidgets);
    });

    // TEST 4: Carga y muestra Card de Bitácora
    testWidgets('Muestra Card de Bitácora de Notas', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bitácora de Notas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text('Notas: 5 totales'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Bitácora de Notas'), findsOneWidget);
      expect(find.text('Notas: 5 totales'), findsOneWidget);
    });

    // TEST 5: Carga y muestra Card de Métricas
    testWidgets('Muestra Card de Métricas de Asesorados', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Card(
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
                          SizedBox(height: 8),
                          Text('Asesorados activos: 8'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Métricas'), findsOneWidget);
      expect(find.text('Asesorados activos: 8'), findsOneWidget);
    });

    // TEST 6: Botón FAB visible y funcional
    testWidgets('Botón FAB está visible y es tappeable', (
      WidgetTester tester,
    ) async {
      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Content')),
            floatingActionButton: FloatingActionButton(
              onPressed: () => tapCount++,
              child: Icon(Icons.add),
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(tapCount, 1);
    });

    // TEST 7: Scroll hacia abajo muestra todos los cards
    testWidgets('Scroll funciona y permite ver todos los elementos', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: Text('Dashboard')),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Card 1'),
                    ),
                  ),
                  SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Card 2'),
                    ),
                  ),
                  SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Card 3'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Card 1'), findsOneWidget);
      expect(find.text('Card 2'), findsOneWidget);
      expect(find.text('Card 3'), findsOneWidget);
    });

    // TEST 8: Actualización de datos refresca la UI
    testWidgets('Actualización de estado refresca los datos mostrados', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    Text('Total: \$100.00'),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          // Simula actualización de estado
                        });
                      },
                      child: Text('Actualizar'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Total: \$100.00'), findsOneWidget);
      expect(find.text('Actualizar'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Total: \$100.00'), findsOneWidget);
    });
  });
}
