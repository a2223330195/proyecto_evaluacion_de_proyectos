# 📚 Ejemplos de Uso - Módulo de Pagos Refactorizado

---

## 1. Registrar un Abono Parcial

```dart
// En PagosPendientesBloc o cualquier BLoC
final pagosService = PagosService();

try {
  final resultado = await pagosService.registrarAbono(
    asesoradoId: 42,
    monto: 25.50,
    nota: 'Pago parcial cliente',
  );

  print('Período: ${resultado['periodo']}');
  print('Total abonado: ${resultado['total_abonado']}');
  print('Saldo pendiente: ${resultado['saldo_pendiente']}');
  print('Periodo completado: ${resultado['periodo_completado']}');

  // Si el período se completa, la membresía se extiende automáticamente
  if (resultado['periodo_completado'] as bool) {
    print('✅ Membresía extendida automáticamente');
  }

  // Invalidar caché del coach para que otras pantallas se actualicen
  pagosService.invalidarCacheCoach(coachId);

} on Exception catch (e) {
  // Ejemplo: 'No se puede registrar abono sin plan activo asignado'
  print('Error: ${e.toString()}');
}
```

---

## 2. Registrar un Pago Completo

```dart
try {
  final resultado = await pagosService.completarPago(
    asesoradoId: 42,
    monto: 49.99,
    nota: 'Pago completo del mes',
  );

  print('Período: ${resultado['periodo']}');
  print('Saldo pendiente: ${resultado['saldo_pendiente']}');

  // Igualmente, la membresía se extiende si el saldo se completa
  if (resultado['periodo_completado'] as bool) {
    print('✅ Período completado, membresía extendida');
  }

  // Invalidar caché
  pagosService.invalidarCacheCoach(coachId);

} on Exception catch (e) {
  print('Error: ${e.toString()}');
}
```

---

## 3. Obtener el Estado del Pago

```dart
final estadoData = await pagosService.obtenerEstadoPago(asesoradoId);

final estado = estadoData['estado'] as String; // Uno de: sin_plan, sin_vencimiento, vencido, proximo_vencimiento, activo, pagado
final saldoPendiente = estadoData['saldo_pendiente'] as double;
final fechaVencimiento = estadoData['fecha_vencimiento'] as DateTime?;
final costoPlan = estadoData['costo_plan'] as double;
final diasHastaVencimiento = estadoData['dias_hasta_vencimiento'] as int;

switch (estado) {
  case 'sin_plan':
    print('El asesorado no tiene plan asignado');
    break;
  case 'sin_vencimiento':
    print('Tiene plan pero sin fecha de vencimiento');
    break;
  case 'vencido':
    print('Pago vencido hace ${-diasHastaVencimiento} días');
    break;
  case 'proximo_vencimiento':
    print('Vencimiento en $diasHastaVencimiento días');
    break;
  case 'activo':
    print('Saldo pendiente: \$$saldoPendiente');
    break;
  case 'pagado':
    print('✅ Período completamente pagado');
    break;
}
```

---

## 4. Obtener Pagos Pendientes con Caché

```dart
// BLoCs pueden usar esto con caché automático
final asesorados = await pagosService.obtenerAsesoradosConPagosPendientes(
  coachId: 5,
  page: 0,
  pageSize: 20,
);

print('Encontrados ${asesorados.length} asesorados con pagos pendientes');
for (final a in asesorados) {
  print('${a.nombre}: \$${a.montoPendiente} pendiente (${a.estado})');
}

// El caché se mantiene automáticamente con clave: 'pagos_pendientes_5_0_20'
// Próxima llamada usará el caché (válido por 5 minutos)
```

---

## 5. Filtrar por Estado de Pago Pendiente

```dart
// Obtener solo pagos atrasados (con caché)
final atrasados = await pagosService.obtenerAsesoradosConPagosAtrasados(coachId: 5);
print('Pagos atrasados: ${atrasados.length}');

// Obtener solo pagos próximos a vencer (próximos 7 días)
final proximos = await pagosService.obtenerAsesoradosConPagosProximos(coachId: 5);
print('Vencimientos próximos: ${proximos.length}');

// Ambos usan caché automático
```

---

## 6. Invalidar Caché Correctamente

```dart
// Después de registrar un pago, invalidar TODAS las variantes de caché
pagosService.invalidarCacheCoach(coachId);

// Esto elimina:
// - 'pagos_pendientes_5_0_20'
// - 'pagos_pendientes_5_1_20'
// - ... todas las variantes paginadas
// - 'pagos_atrasados_5'
// - 'pagos_proximos_5'

// Próximas llamadas obtendrán datos frescos de la BD
```

---

## 7. En PagosPendientesBloc - Cargar con Validaciones

```dart
class PagosPendientesBloc extends Bloc<...> {
  final PagosService _pagosService = PagosService();

  Future<void> _onCargarPagosPendientes(
    CargarPagosPendientes event,
    Emitter<PagosPendientesState> emit,
  ) async {
    emit(const PagosPendientesLoading());
    try {
      // Cargar asesorados con pagos pendientes
      final asesoradosBase = await _pagosService.obtenerAsesoradosConPagosPendientes(
        event.coachId,
        page: event.pageNumber - 1,
        pageSize: 20,
      );

      // Actualizar con estados de pago frescos
      final asesoradosConEstado = await Future.wait(
        asesoradosBase.map((a) async {
          final estado = await _pagosService.obtenerEstadoPago(a.asesoradoId);
          return a.copyWith(
            estado: _mapearEstado(estado['estado'] as String),
            montoPendiente: estado['saldo_pendiente'] as double,
            fechaVencimiento: estado['fecha_vencimiento'] as DateTime?,
          );
        }),
      );

      // Aplicar filtros y búsqueda
      final filtered = _aplicarFiltros(
        asesoradosConEstado,
        filtro: event.filtroEstado,
        query: event.searchQuery,
      );

      // ✅ IMPORTANTE: Recalcular totalCount basado en filtrados
      final totalCount = filtered.length;
      final totalPages = totalCount == 0 ? 1 : (totalCount / 20).ceil();

      emit(
        PagosPendientesLoaded(
          asesoradosConPago: filtered,
          allAsesorados: asesoradosConEstado,
          currentPage: event.pageNumber,
          totalPages: totalPages,
          totalCount: totalCount, // ✅ Respeta filtros
          totalMontoPendiente: filtered.fold(0.0, (sum, a) => sum + a.montoPendiente),
        ),
      );

    } catch (e) {
      emit(PagosPendientesError('Error: ${e.toString()}'));
    }
  }

  Future<void> _onRegistrarAbonoPendiente(
    RegistrarAbonoPendiente event,
    Emitter<PagosPendientesState> emit,
  ) async {
    try {
      // ✅ Servicio ya valida plan activo
      final resultado = await _pagosService.registrarAbono(
        asesoradoId: event.asesoradoId,
        monto: event.monto,
        nota: event.nota,
      );

      // ✅ Invalidar caché para reflejar cambios en todas partes
      _pagosService.invalidarCacheCoach(event.coachId);

      // Recargar lista para mostrar cambios
      add(CargarPagosPendientes(...));

    } on Exception catch (e) {
      emit(PagosPendientesError(e.toString()));
    }
  }
}
```

---

## 8. Contar Asesorados con Pagos Pendientes

```dart
final count = await pagosService.obtenerCountAsesoradosConPagosPendientes(coachId: 5);
print('Total de asesorados con pagos pendientes: $count');

// Útil para mostrar badges en el UI
```

---

## 9. Obtener Total de Dinero Pendiente

```dart
final totalPendiente = await pagosService.obtenerTotalPagosPendientes(coachId: 5);
print('Total pendiente de recaudar: \$$totalPendiente');

// Útil para dashboard o resumen de ingresos
```

---

## 10. Obtener Pagos Paginados de un Asesorado

```dart
// Con paginación y retry automático
final pagos = await pagosService.getPagosByAsesoradoPaginated(
  asesoradoId: 42,
  pageNumber: 1,
  pageSize: 10,
  ordenarPorPeriodo: true, // false = por fecha DESC
);

for (final pago in pagos) {
  print('${pago.fechaPago}: \$${pago.monto} (${pago.tipo.name})');
}

// Total de páginas
final totalPages = await pagosService.getTotalPages(42, pageSize: 10);
print('Total de páginas: $totalPages');
```

---

## 11. Obtener Resumen de Pagos por Mes (Contabilidad)

```dart
final resumen = await pagosService.obtenerResumenPagosPorMes(coachId: 5);

for (final mes in resumen) {
  final periodo = mes['periodo'] as String; // '2025-11'
  final cantidad = mes['cantidad_pagos'] as int;
  final completos = mes['pagos_completos'] as int;
  final abonos = mes['abonos'] as int;
  final total = mes['total_recaudado'] as double;

  print('''
  Período: $periodo
    - Total pagos: $cantidad ($completos completos + $abonos abonos)
    - Total recaudado: \$$total
  ''');
}
```

---

## 12. Verificar si Asesorado Tiene Plan Activo

```dart
final tienePlan = await pagosService.tieneActivoPlan(asesoradoId: 42);

if (tienePlan) {
  // Seguro: puede registrar abono
  await pagosService.registrarAbono(...);
} else {
  // Mostrar mensaje: Asignar plan primero
  print('Asigne un plan antes de registrar pagos');
}
```

---

## 13. Obtener Costo del Plan

```dart
final costoPlan = await pagosService.obtenerCostoPlan(asesoradoId: 42);
print('Costo del plan: \$$costoPlan');

// Útil para validaciones en UI
```

---

## 14. Búsqueda en Pagos Pendientes

```dart
// Buscar en pagos pendientes
final resultados = await pagosService.buscarAsesoradosConPagosPendientes(
  coachId: 5,
  query: 'juan',
);

for (final a in resultados) {
  print('${a.nombre}: \$${a.montoPendiente}');
}

// Búsqueda simple por nombre, case-insensitive
```

---

## 15. Limpiar Todo el Caché (Último Recurso)

```dart
// Solo si hay problemas de caché
pagosService.limpiarCache();

// Limpia:
// - Todos los pagos pendientes paginados
// - Todos los pagos atrasados
// - Todos los pagos próximos
// - Caché secundario de pagos individuales
```

---

## ⚠️ Errores Comunes y Cómo Evitarlos

### ❌ Error: "No se puede registrar abono sin plan activo asignado"

**Causa:** Intentar registrar pago sin asignar plan al asesorado

**Solución:**
```dart
// Validar ANTES de intentar registrar
final tienePlan = await pagosService.tieneActivoPlan(asesoradoId);
if (!tienePlan) {
  print('Asigne un plan al asesorado primero');
  return;
}

// Ahora es seguro registrar
await pagosService.registrarAbono(...);
```

### ❌ Error: Caché no se actualiza después de registrar pago

**Causa:** No invalidar caché después de operación

**Solución:**
```dart
// SIEMPRE después de registrar pago o abono:
await pagosService.registrarAbono(...);
pagosService.invalidarCacheCoach(coachId); // ← IMPORTANTE

// Próximas llamadas obtendrán datos frescos
```

### ❌ Error: totalCount no coincide con resultados filtrados

**Causa:** No recalcular totalCount cuando se aplican filtros

**Solución:**
```dart
// SIEMPRE después de filtrar:
final filtered = _aplicarFiltros(asesorados, filtro: f);
final totalCount = filtered.length; // ← Recalcular
final totalPages = (totalCount / pageSize).ceil();

emit(state.copyWith(
  totalCount: totalCount,
  totalPages: totalPages,
));
```

---

**Nota:** Todos estos ejemplos son compatibles con los BLoCs existentes y no requieren cambios en la UI.
