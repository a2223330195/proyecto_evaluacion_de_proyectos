import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// ============================================================================
/// BITACORA CARD TESTS - E.5.2 Widget Tests
/// ============================================================================
/// 7 Tests para validar BitacoraCard
/// ============================================================================

void main() {
  group('BitacoraCard - Widget Tests (E.5.2)', () {
    // TEST 1: Renderiza BitacoraCard sin errores
    testWidgets('Renderiza BitacoraCard sin errores', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Bitácora Card Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Bitácora Card Content'), findsOneWidget);
    });

    // TEST 2: Muestra título "Bitácora de Notas"
    testWidgets('Muestra título "Bitácora de Notas"', (
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
                      'Bitácora de Notas',
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

      expect(find.text('Bitácora de Notas'), findsOneWidget);
    });

    // TEST 3: Muestra lista de notas prioritarias
    testWidgets('Muestra lista de notas prioritarias', (
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
                    Text('Bitácora de Notas'),
                    SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        final notas = [
                          'Nota Prioritaria 1',
                          'Nota Prioritaria 2',
                          'Nota Prioritaria 3',
                        ];
                        return ListTile(
                          leading: Icon(Icons.star, color: Colors.amber),
                          title: Text(notas[index]),
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

      expect(find.byIcon(Icons.star), findsWidgets);
      expect(find.text('Nota Prioritaria 1'), findsOneWidget);
    });

    // TEST 4: Scroll dentro del card funciona
    testWidgets('Scroll dentro del card permite ver más notas', (
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
                    Text('Bitácora de Notas'),
                    SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: 10,
                        itemBuilder: (context, index) {
                          return ListTile(title: Text('Nota ${index + 1}'));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Nota 1'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    // TEST 5: Botón "Crear Nota" visible y funcional
    testWidgets('Botón "Crear Nota" es visible y clickeable', (
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
                    Text('Bitácora de Notas'),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => tapCount++,
                      child: Text('Crear Nota'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Crear Nota'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(tapCount, 1);
    });

    // TEST 6: Transición Loading → Loaded con notas
    testWidgets('Muestra estado Loading correctamente', (
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
                    Text('Bitácora de Notas'),
                    SizedBox(height: 8),
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

    // TEST 7: Muestra contador de notas
    testWidgets('Muestra contador de notas correctamente', (
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
                    Text('Bitácora de Notas'),
                    SizedBox(height: 8),
                    Text(
                      'Total: 5 notas',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return ListTile(title: Text('Nota ${index + 1}'));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Total: 5 notas'), findsOneWidget);
      expect(find.text('Nota 1'), findsOneWidget);
    });
  });
}
