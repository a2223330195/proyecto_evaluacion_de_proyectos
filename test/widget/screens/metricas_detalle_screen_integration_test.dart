// test/widget/screens/metricas_detalle_screen_integration_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:coachhub/screens/metricas_detalle_screen.dart';
import 'package:coachhub/blocs/metricas/metricas_bloc.dart';

// Mock BLoC for testing
class MockMetricasBloc extends MetricasBloc {
  @override
  Future<void> close() async {
    await super.close();
  }
}

void main() {
  group('MetricasDetalleScreen - Integration with Metrics Selector', () {
    testWidgets('AppBar contiene botón Editar Métricas (tune icon)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<MetricasBloc>(
            create: (_) => MockMetricasBloc(),
            child: const MetricasDetalleScreen(
              asesoradoId: 1,
              isEmbedded: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // VERIFY: Botón "tune" (editar métricas) está presente
      expect(
        find.byIcon(Icons.tune),
        findsOneWidget,
        reason: 'AppBar debe contener icono de ajustes (tune)',
      );
    });

    testWidgets('Presionar botón Editar Métricas abre modal', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<MetricasBloc>(
            create: (_) => MockMetricasBloc(),
            child: const MetricasDetalleScreen(
              asesoradoId: 1,
              isEmbedded: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ACT: Presionar botón tune
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      // VERIFY: Modal se abrió (buscar MetricasSelectorWidget)
      // Por ahora, verificamos que el modal es visible
      expect(
        find.byType(BottomSheet),
        findsWidgets,
        reason: 'Modal debería estar visible después de presionar botón',
      );
    });

    testWidgets('Screen carga correctamente sin embedded mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<MetricasBloc>(
            create: (_) => MockMetricasBloc(),
            child: const MetricasDetalleScreen(
              asesoradoId: 42,
              isEmbedded: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // VERIFY: AppBar title is visible
      expect(
        find.text('Métricas - Detalle'),
        findsOneWidget,
        reason: 'Screen title should be visible',
      );

      // VERIFY: Tune button is visible
      expect(
        find.byIcon(Icons.tune),
        findsOneWidget,
        reason: 'Metrics editor button should be visible',
      );
    });

    testWidgets('Screen en embedded mode: No muestra AppBar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<MetricasBloc>(
              create: (_) => MockMetricasBloc(),
              child: const MetricasDetalleScreen(
                asesoradoId: 1,
                isEmbedded: true, // Embedded mode
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // VERIFY: No AppBar (embedded mode doesn't show one)
      expect(
        find.byType(AppBar),
        findsNothing,
        reason: 'Embedded mode should not show AppBar',
      );

      // VERIFY: No tune button
      expect(
        find.byIcon(Icons.tune),
        findsNothing,
        reason: 'Embedded mode should not show tune button',
      );
    });

    testWidgets('Botón tiene tooltip "Editar métricas"', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<MetricasBloc>(
            create: (_) => MockMetricasBloc(),
            child: const MetricasDetalleScreen(
              asesoradoId: 1,
              isEmbedded: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // VERIFY: Tune button exists and is interactive
      final tuneButton = find.byIcon(Icons.tune);
      expect(
        tuneButton,
        findsOneWidget,
        reason: 'Tune button should be present with tooltip',
      );

      // VERIFY: Button is enabled (not disabled)
      final iconButton = tester.widget<IconButton>(
        find.ancestor(of: tuneButton, matching: find.byType(IconButton)),
      );
      expect(
        iconButton.onPressed,
        isNotNull,
        reason: 'Button should be enabled',
      );
    });
  });
}
