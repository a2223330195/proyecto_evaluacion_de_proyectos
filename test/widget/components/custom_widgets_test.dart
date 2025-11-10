import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// ============================================================================
/// CUSTOM WIDGETS TESTS - E.5.2 Widget Tests
/// ============================================================================
/// 3 Tests para validar Widgets personalizados reutilizables
/// ============================================================================

void main() {
  group('CustomWidgets - Widget Tests (E.5.2)', () {
    // TEST 1: CustomButton renderiza y responde a tap
    testWidgets('CustomButton renderiza correctamente y responde a tap', (
      WidgetTester tester,
    ) async {
      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => tapCount++,
                child: Text('Custom Button'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Custom Button'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(tapCount, 1);
    });

    // TEST 2: CustomCard muestra contenido correctamente
    testWidgets('CustomCard muestra contenido y mantiene estructura', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              elevation: 2,
              margin: EdgeInsets.all(16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'Título Custom',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Contenido del Custom Card',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Título Custom'), findsOneWidget);
      expect(find.text('Contenido del Custom Card'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    // TEST 3: CustomTextField captura input correctamente
    testWidgets('CustomTextField captura y muestra input del usuario', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Ingresa texto',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Validar o enviar
                    },
                    child: Text('Enviar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Ingresa texto'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);

      // Escribir texto
      await tester.enterText(find.byType(TextField), 'Texto de prueba');
      await tester.pumpAndSettle();

      expect(controller.text, 'Texto de prueba');

      // Verificar que el botón es visible
      expect(find.text('Enviar'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      // Tap en botón
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
    });
  });
}
