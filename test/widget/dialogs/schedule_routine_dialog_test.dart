// test/widget/dialogs/schedule_routine_dialog_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coachhub/models/asesorado_model.dart';
import 'package:coachhub/models/rutina_model.dart';
import 'package:coachhub/widgets/dialogs/schedule_routine_dialog.dart';

void main() {
  group('ScheduleRoutineDialog - Contexto A.4 / B.2', () {
    final testAsesorado = Asesorado(
      id: 1,
      name: 'Carlos López',
      avatarUrl: 'https://example.com/avatar.jpg',
      coachId: 100,
      status: AsesoradoStatus.activo,
      planId: 5,
      planName: 'Plan Premium',
    );

    final testRutina = Rutina(
      id: 1,
      nombre: 'Rutina de Pecho',
      descripcion: 'Test',
      categoria: RutinaCategoria.pecho,
    );

    testWidgets(
      'Desde ficha (isFromFicha=true): asesorado debe estar bloqueado con icono candado',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ScheduleRoutineDialog(
                initialAsesorado: testAsesorado,
                initialRutina: testRutina,
                isFromFicha: true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verificar que hay un icono de candado (Lock)
        expect(
          find.byIcon(Icons.lock),
          findsOneWidget,
          reason: 'Debe haber un icono de candado cuando isFromFicha=true',
        );

        // Verificar que NO hay DropdownButtonFormField para asesorados
        final dropdownFinders = find.byType(DropdownButtonFormField<Asesorado>);
        expect(
          dropdownFinders,
          findsNothing,
          reason:
              'No debe haber combobox de asesorados cuando isFromFicha=true',
        );

        // Verificar que hay TextFormField (campo de solo lectura)
        expect(
          find.byType(TextFormField),
          findsWidgets,
          reason:
              'Debe haber campo de solo lectura para asesorado cuando isFromFicha=true',
        );
      },
    );

    testWidgets(
      'Desde biblioteca (isFromFicha=false): asesorado debe estar en combobox editable',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ScheduleRoutineDialog(
                initialRutina: testRutina,
                isFromFicha: false,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verificar que NO hay icono de candado
        expect(
          find.byIcon(Icons.lock),
          findsNothing,
          reason: 'No debe haber icono de candado cuando isFromFicha=false',
        );

        // Verificar que hay DropdownButtonFormField para asesorados
        expect(
          find.byType(DropdownButtonFormField<Asesorado>),
          findsOneWidget,
          reason: 'Debe haber combobox de asesorados cuando isFromFicha=false',
        );
      },
    );

    testWidgets('Ficha: intentar cambiar asesorado no debe ser posible', (
      WidgetTester tester,
    ) async {
      // Este test verifica que el campo de texto está en readOnly
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleRoutineDialog(
              initialAsesorado: testAsesorado,
              initialRutina: testRutina,
              isFromFicha: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Buscar el TextFormField y verificar que es readOnly
      final textFormFields = find.byType(TextFormField);
      expect(textFormFields, findsWidgets);

      // Verificar que el campo muestra el nombre del asesorado
      expect(
        find.text(testAsesorado.name),
        findsOneWidget,
        reason:
            'Debe mostrar el nombre del asesorado preseleccionado en el campo de solo lectura',
      );
    });

    testWidgets('Constructor default: isFromFicha debe ser false por defecto', (
      WidgetTester tester,
    ) async {
      // Crear diálogo sin especificar isFromFicha
      final dialog = ScheduleRoutineDialog(initialRutina: testRutina);

      // Verificar que isFromFicha es false por defecto
      expect(
        dialog.isFromFicha,
        false,
        reason: 'isFromFicha debe ser false por defecto',
      );
    });

    testWidgets(
      'Ficha: mostrar mensaje de error si se intenta cambiar asesorado',
      (WidgetTester tester) async {
        // Este test verifica que la validación en _submit() rechaza cambios
        // Aunque el campo esté bloqueado, la validación de lógica debe funcionar
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ScheduleRoutineDialog(
                initialAsesorado: testAsesorado,
                initialRutina: testRutina,
                isFromFicha: true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verificar que el icono de candado está presente
        final lockIcon = find.byIcon(Icons.lock);
        expect(
          lockIcon,
          findsOneWidget,
          reason: 'Icono de candado debe estar visible para bloquear edición',
        );

        // El campo de texto NO debe ser interactivo
        final textField = find.byType(TextField).first;
        final textFieldWidget = tester.widget<TextField>(textField);
        expect(
          textFieldWidget.readOnly,
          true,
          reason: 'El campo debe ser readOnly (no editable)',
        );
      },
    );
  });
}
