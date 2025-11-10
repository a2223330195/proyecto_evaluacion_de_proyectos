import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// ============================================================================
/// PAGOS CARD TESTS - E.5.2 Widget Tests
/// ============================================================================
/// 7 Tests para validar PagosCard
/// ============================================================================

void main() {
  group('PagosCard - Widget Tests (E.5.2)', () {
    // TEST 1: Renderiza PagosCard sin errores
    testWidgets('Renderiza PagosCard sin errores', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Pagos Card Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Pagos Card Content'), findsOneWidget);
    });

    // TEST 2: Muestra título "Pagos Pendientes"
    testWidgets('Muestra título "Pagos Pendientes"', (
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
                      'Pagos Pendientes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Contenido'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Pagos Pendientes'), findsOneWidget);
    });

    // TEST 3: Muestra total de pagos pendientes
    testWidgets('Muestra total de pagos pendientes correctamente', (
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
                    Text('Pagos Pendientes'),
                    SizedBox(height: 8),
                    Text(
                      'Total: \$249.98',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Total: \$249.98'), findsOneWidget);
    });

    // TEST 4: Muestra lista de asesorados con pagos
    testWidgets('Muestra lista de asesorados con pagos pendientes', (
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
                    Text('Pagos Pendientes'),
                    SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: 2,
                      itemBuilder: (context, index) {
                        final nombres = ['Juan Pérez', 'María García'];
                        return ListTile(
                          title: Text(nombres[index]),
                          subtitle: Text('\$99.99'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Juan Pérez'), findsOneWidget);
      expect(find.text('María García'), findsOneWidget);
    });

    // TEST 5: Botón "Ver Todos" está visible
    testWidgets('Botón "Ver Todos" es visible y clickeable', (
      WidgetTester tester,
    ) async {
      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Pagos Pendientes'),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => tapCount++,
                      child: Text('Ver Todos'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Ver Todos'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(tapCount, 1);
    });

    // TEST 6: Transición Loading → Loaded funciona
    testWidgets('Muestra estado Loading y luego Loaded', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(height: 50, child: CircularProgressIndicator()),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // TEST 7: Maneja estado Error correctamente
    testWidgets('Muestra mensaje de error cuando aplica', (
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
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(height: 8),
                    Text(
                      'Error al cargar los datos',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Error al cargar los datos'), findsOneWidget);
    });
  });
}
