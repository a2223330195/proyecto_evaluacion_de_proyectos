# 🔄 GUÍA DE MIGRACIÓN - Código Legado → Nuevo Sistema

Para cualquier desarrollador que tenga código usando el sistema antiguo de pagos.

---

## 📋 Búsqueda y Reemplazo Rápido

### Si estabas usando `PagosPendientesService`

**Antes:**
```dart
import 'package:coachhub/services/pagos_pendientes_service.dart';

final service = PagosPendientesService(DatabaseConnection.instance);
```

**Ahora:**
```dart
import 'package:coachhub/services/pagos_service.dart';

final service = PagosService();
```

---

## 🔧 Cambios por Caso de Uso

### 1. Obtener Pagos Pendientes

**Antes:**
```dart
final service = PagosPendientesService(db);
final pendientes = await service.obtenerAsesoradosConPagosPendientes(coachId);
```

**Ahora (Idéntico):**
```dart
final service = PagosService();
final pendientes = await service.obtenerAsesoradosConPagosPendientes(coachId);
// Los cambios son internos, la interfaz es la misma
```

### 2. Registrar Pago

**Antes:**
```dart
// Validación manual
final costoPlan = await service.obtenerCostoPlan(asesoradoId);
if (costoPlan <= 0) {
  throw Exception('Sin plan');
}
// Registro manual
await service.createPago(newPago);
// Invalidación manual y separada
```

**Ahora (Automático):**
```dart
// Validación incluida en el servicio
final resultado = await service.registrarAbono(
  asesoradoId: asesoradoId,
  monto: monto,
);
// Automáticamente:
// 1. Valida plan
// 2. Inserta pago
// 3. Calcula saldo
// 4. Si completa: extiende membresía
// 5. Invalida caché
```

### 3. Obtener Estado de Pago

**Antes:**
```dart
// Lógica dispersa en múltiples lugares
final datos = await db.query('SELECT ...');
// Múltiples condicionales para determinar estado
String estado = 'pendiente';
if (...) estado = 'deudor';
// etc...
```

**Ahora (Centralizado):**
```dart
final estadoData = await service.obtenerEstadoPago(asesoradoId);
final estado = estadoData['estado']; // Uno de 6 estados definidos

// Estados posibles:
// 'sin_plan'
// 'sin_vencimiento'
// 'vencido'
// 'proximo_vencimiento'
// 'activo'
// 'pagado'
```

### 4. Invalidar Caché

**Antes:**
```dart
// Múltiples llamadas dispersas
_cache.remove('pagos_$coachId');
_cache.remove('pagos_atrasados');
_cache.remove('pagos_proximos');
// Posiblemente incompleto...
```

**Ahora (Único método):**
```dart
// Una llamada que limpia TODAS las variantes
service.invalidarCacheCoach(coachId);
```

---

## 🚨 Cosas Que Cambiaron

### Estado del Pago

**Valores antiguos:**
```
'activo', 'pendiente', 'deudor', 'proximo', etc. (inconsistente)
```

**Nuevos valores (normalizados):**
```
'sin_plan', 'sin_vencimiento', 'vencido', 'proximo_vencimiento', 'activo', 'pagado'
```

**Migración en BLoCs:**
```dart
String _mapearEstadoAntigoAlNuevo(String oldEstado) {
  switch (oldEstado) {
    case 'deudor':
      return 'vencido';
    case 'proximo':
      return 'proximo_vencimiento';
    case 'activo':
      return 'activo';
    default:
      return 'pendiente'; // Fallback
  }
}
```

### Método de Cálculo de Saldo

**Antes:** Múltiples implementaciones
**Ahora:** `_obtenerSaldoPeriodo()` únicamente

No necesitas cambiar nada, el servicio lo maneja internamente.

---

## ✅ Checklist de Migración

- [ ] Cambiar importes de `PagosPendientesService` a `PagosService`
- [ ] Actualizar inicialización: `PagosService()` en lugar de `PagosPendientesService(db)`
- [ ] Si usabas `createPago()`: cambiar a `registrarAbono()` o `completarPago()`
- [ ] Si validabas plan: remover, ahora lo hace el servicio
- [ ] Si invalidabas caché: unificar en `invalidarCacheCoach()`
- [ ] Si interpretabas estados: mapear a los 6 nuevos estados
- [ ] Ejecutar `flutter analyze` para verificar
- [ ] Prueba manual de pagos pendientes

---

## 🧪 Prueba de Migración

```dart
// Viejo flujo (disperso)
final service = PagosPendientesService(db);
if (await service.tieneActivoPlan(asesoradoId)) {
  await service.createPago(pago);
  service.invalidarCacheCoach(coachId); // Posiblemente incompleto
}

// Nuevo flujo (limpio)
final service = PagosService();
try {
  final resultado = await service.registrarAbono(
    asesoradoId: asesoradoId,
    monto: monto,
  );
  // ✅ Todo hecho automáticamente:
  // - Validación
  // - Inserción
  // - Cálculo
  // - Extensión si completa
  // - Invalidación correcta
} on Exception catch (e) {
  print('Error: $e');
}
```

---

## 🎯 Cambios Esperados en Tests

### Antes
```dart
test('Crear pago', () async {
  final service = PagosPendientesService(mockDb);
  
  // Múltiples pasos
  await service.createPago(...);
  verify(mockDb.query(...)).called(1);
  // etc...
});
```

### Ahora
```dart
test('Registrar abono', () async {
  final service = PagosService();
  
  // Más limpio
  final resultado = await service.registrarAbono(...);
  
  expect(resultado['periodo_completado'], isTrue);
  // Validaciones automáticas
});
```

---

## 📞 Soporte

Si tienes código que no cabe exactamente en esta guía:

1. Revisa `EJEMPLOS_USO_PAGOS.md` para 15+ casos de uso
2. Revisa `REFACTORIZACIÓN_PAGOS_COMPLETA.md` para detalles técnicos
3. Usa `flutter analyze` para detectar problemas
4. Los métodos están documentados con DocStrings

---

## ⚡ Casos de Uso Específicos

### Caso: Actualizar estado en tiempo real

**Antes:**
```dart
// Tenías que calcular manualmente cada vez
final estadoCalculo = ...;
```

**Ahora:**
```dart
// Siempre fresco, una sola llamada
final estadoData = await service.obtenerEstadoPago(asesoradoId);
```

### Caso: Mostrar lista con sincronización

**Antes:**
```dart
// Múltiples invalidaciones dispersas
_cache.remove(...);
_cache.remove(...);
```

**Ahora:**
```dart
// Una sola llamada
service.invalidarCacheCoach(coachId);
// Todas las variantes limpias
```

### Caso: Validar antes de operación

**Antes:**
```dart
// Validación manual en cada BLoC
if (costoPlan <= 0) throw Exception(...);
```

**Ahora:**
```dart
// El servicio valida automáticamente
await service.registrarAbono(...); // Lanza excepción si no hay plan
```

---

## 🎊 Conclusión

La migración es **mínima** porque:
- La interfaz pública es la misma
- Los cambios son internos
- El servicio se inicializa igual
- Los métodos funcionan igual

**Tiempo estimado de migración:** 15-30 minutos máximo

---

*Última actualización: 10 de noviembre de 2025*
