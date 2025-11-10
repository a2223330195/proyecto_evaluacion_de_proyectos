import 'package:coachhub/models/asesorado_pago_pendiente.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// ============================================================================
/// TEST HELPERS - E.5.2 Widget Tests
/// ============================================================================
/// Utilidades, datos de prueba y extensiones para tests de widgets
/// ============================================================================

// ============================================================================
// DATOS DE PRUEBA
// ============================================================================

/// Datos de prueba para AsesoradoPagoPendiente
final asesoradoPagoPendienteTest = AsesoradoPagoPendiente(
  asesoradoId: 1,
  nombre: 'Juan Pérez',
  fotoPerfil: 'https://example.com/juan.jpg',
  plan: 'Premium',
  fechaVencimiento: DateTime.now().add(Duration(days: 5)),
  costoPlan: 99.99,
  montoPendiente: 99.99,
  estado: 'proximo',
);

/// Datos de prueba para Nota
final notaTest = Nota(
  notaId: 1,
  asesoradoId: 1,
  titulo: 'Revisión de progreso',
  contenido: 'El asesorado ha mostrado buen progreso esta semana.',
  prioritaria: true,
  fechaCreacion: DateTime.now(),
);

/// Lista de asesorados para testing
final asesoradosListTest = [
  AsesoradoPagoPendiente(
    asesoradoId: 1,
    nombre: 'Juan Pérez',
    fotoPerfil: 'https://example.com/juan.jpg',
    plan: 'Premium',
    fechaVencimiento: DateTime.now().add(Duration(days: 2)),
    costoPlan: 99.99,
    montoPendiente: 99.99,
    estado: 'proximo',
  ),
  AsesoradoPagoPendiente(
    asesoradoId: 2,
    nombre: 'María García',
    fotoPerfil: 'https://example.com/maria.jpg',
    plan: 'Basic',
    fechaVencimiento: DateTime.now().add(Duration(days: 10)),
    costoPlan: 49.99,
    montoPendiente: 49.99,
    estado: 'pendiente',
  ),
];

/// Lista de notas para testing
final notasListTest = [
  Nota(
    notaId: 1,
    asesoradoId: 1,
    titulo: 'Primera nota',
    contenido: 'Contenido de la primera nota',
    prioritaria: true,
    fechaCreacion: DateTime.now(),
  ),
  Nota(
    notaId: 2,
    asesoradoId: 1,
    titulo: 'Segunda nota',
    contenido: 'Contenido de la segunda nota',
    prioritaria: false,
    fechaCreacion: DateTime.now().subtract(Duration(days: 1)),
  ),
];

// ============================================================================
// UTILIDADES DE RENDERING
// ============================================================================

/// Wrapper para aplicación con tema material
Widget materializeApp(Widget widget) {
  return MaterialApp(
    home: Scaffold(body: widget),
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    ),
  );
}

/// Wrapper con BLoC providers (simplificado)
Widget withBlocProviders({required Widget child}) {
  return child;
}

// ============================================================================
// EXTENSIONES PARA TESTER
// ============================================================================

/// Extensión para facilitar testing
extension WidgetTesterExtension on WidgetTester {
  /// Pumps widget y espera a que se complete
  Future<void> pumpMaterialApp(Widget widget) async {
    await pumpWidget(materializeApp(widget));
  }

  /// Busca widget por tipo en la UI
  Finder findByType<T>() => find.byType(T);

  /// Busca widget por texto
  Finder findByText(String text) => find.text(text);

  /// Busca widget por icon
  Finder findByIcon(IconData icon) => find.byIcon(icon);

  /// Busca botón por tipo
  Finder findButton() => find.byType(ElevatedButton);

  /// Hace tap en widget y espera
  Future<void> tapAndSettle(Finder finder) async {
    await tap(finder);
    await pumpAndSettle();
  }

  /// Verifica que widget sea visible
  void expectVisible(Finder finder) {
    expect(finder, findsWidgets);
  }

  /// Verifica que widget NO sea visible
  void expectNotVisible(Finder finder) {
    expect(finder, findsNothing);
  }

  /// Scroll hasta encontrar widget
  Future<void> scrollUntilVisible(
    Finder finder, {
    double scrollDelta = -300.0,
    int maxScrolls = 5,
  }) async {
    int scrollCount = 0;
    while (scrollCount < maxScrolls) {
      await drag(find.byType(ListView), Offset(0, scrollDelta));
      await pumpAndSettle(Duration(milliseconds: 200));
      try {
        expect(finder, findsWidgets);
        return;
      } catch (_) {
        scrollCount++;
      }
    }
  }
}

// ============================================================================
// STUBS DE BLOCS PARA TESTING
// ============================================================================

/// Stub de PagosState
abstract class PagosState {}

class PagosInitial extends PagosState {}

class PagosLoading extends PagosState {}

class PagosPendientesLoaded extends PagosState {
  final List<AsesoradoPagoPendiente> asesorados;
  PagosPendientesLoaded(this.asesorados);
}

class PagosError extends PagosState {
  final String message;
  PagosError(this.message);
}

/// Stub de PagosBloc
class PagosBloc {}

/// Stub de BitacoraState
abstract class BitacoraState {}

class BitacoraInitial extends BitacoraState {}

class BitacoraLoading extends BitacoraState {}

class NotasPrioritariasLoaded extends BitacoraState {
  final List<Nota> notas;
  NotasPrioritariasLoaded(this.notas);
}

class BitacoraError extends BitacoraState {
  final String message;
  BitacoraError(this.message);
}

/// Stub de BitacoraBloc
class BitacoraBloc {}

/// Stub de MetricasState
abstract class MetricasState {}

class MetricasInitial extends MetricasState {}

class MetricasLoading extends MetricasState {}

class MetricasLoaded extends MetricasState {
  final List<String> metricas;
  MetricasLoaded(this.metricas);
}

class MetricasError extends MetricasState {
  final String message;
  MetricasError(this.message);
}

/// Stub de MetricasBloc
class MetricasBloc {}

// ============================================================================
// MODELOS STUB
// ============================================================================

/// Stub de Nota
class Nota {
  final int notaId;
  final int asesoradoId;
  final String titulo;
  final String contenido;
  final bool prioritaria;
  final DateTime fechaCreacion;

  Nota({
    required this.notaId,
    required this.asesoradoId,
    required this.titulo,
    required this.contenido,
    required this.prioritaria,
    required this.fechaCreacion,
  });
}

// ============================================================================
// CONSTANTES DE TESTING
// ============================================================================

const int testCoachId = 1;
const String testCoachName = 'Coach Test';
const Duration testAnimationDuration = Duration(milliseconds: 500);
