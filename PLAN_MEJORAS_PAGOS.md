# Plan de Mejoras: Módulo de Pagos/Membresías

**Fecha**: 11 de noviembre de 2025  
**Prioridad General**: Implementar tests integración + refactorizar métodos redundantes  

---

## 📌 Mejoras por Prioridad

### 🔴 P0: CRÍTICAS

#### P0.1 - Crear Tests de Integración con BD Real
**Archivo**: `test/integration/pagos_integration_test.dart` (NUEVO)

**Casos a Validar**:

```dart
void main() {
  group('Pagos Integration Tests - Real Database', () {
    
    test('registrarPago completa período y extiende membresía', () async {
      // Arrange
      final asesoradoId = 1;
      final costoPlan = 5000.0;
      
      // Act
      final resultado1 = await pagosService.registrarPago(
        asesoradoId: asesoradoId,
        monto: 3000.0,
        nota: 'Abono parcial',
      );
      
      // Assert 1: primer pago es abono
      expect(resultado1['tipo_pago'], equals('abono'));
      expect(resultado1['saldo_pendiente'], equals(2000.0));
      
      // Act 2
      final resultado2 = await pagosService.registrarPago(
        asesoradoId: asesoradoId,
        monto: 2000.0,
        nota: 'Completando período',
      );
      
      // Assert 2: segundo pago completa período
      expect(resultado2['tipo_pago'], equals('completo'));
      expect(resultado2['periodo_completado'], isTrue);
      
      // Assert 3: membresía fue extendida
      final estado = await pagosService.obtenerEstadoPago(asesoradoId);
      expect(estado['estado'], equals('activo'));
    });
    
    test('determinación de período con múltiples historiales', () async {
      // Arrange: crear 3 períodos con pagos incompletos
      // 2025-01: 2000/5000 (completo)
      // 2025-02: 1500/5000 (pendiente) ← debe detectar este
      // 2025-03: 0/5000 (no existe)
      
      // Act
      final periodo = await pagosService._determinarPeriodoObjetivo(
        asesoradoId: asesoradoId,
        costoPlan: 5000.0,
        fechaVencimiento: DateTime(2025, 3, 15),
      );
      
      // Assert: debe retornar 2025-02 como período pendiente
      expect(periodo.periodo, equals('2025-02'));
      expect(periodo.saldoPendiente, equals(3500.0));
    });
    
    test('transiciones de estado: activo → próximo_vencimiento → vencido', () async {
      // Setup: crear asesorado con fecha vencimiento hoy+10
      // Assert 1: estado = 'proximo_vencimiento'
      
      // Simular paso de tiempo
      // Assert 2: estado = 'vencido' (cuando fecha < hoy)
      
      // Registrar pago completo
      // Assert 3: estado = 'activo', fecha extendida +30 días
    });
    
    test('invalidación de caché sin side effects', () async {
      // Arrange: cargar lista de asesorados con pagos pendientes
      final lista1 = await pagosService.obtenerAsesoradosConPagosPendientes(
        coachId: 1,
      );
      
      // Act: registrar pago para uno de ellos
      await pagosService.registrarPago(
        asesoradoId: lista1.first.asesoradoId,
        monto: lista1.first.montoPendiente,
      );
      
      // Assert: caché fue invalidado, nueva lista NO contiene ese asesorado
      final lista2 = await pagosService.obtenerAsesoradosConPagosPendientes(
        coachId: 1,
      );
      expect(lista2.length, lessThan(lista1.length));
    });
    
    test('fallback a caché cuando BD falla', () async {
      // Arrange: cargar datos (y cachearlos)
      final lista1 = await pagosService.getPagosByAsesoradoPaginated(
        asesoradoId: 1,
        pageNumber: 1,
      );
      expect(lista1, isNotEmpty);
      
      // Act: desconectar BD
      // (Simular con mock de DatabaseConnection)
      
      // Assert: retorna caché válido (no lanza excepción)
      // Lista debe tener datos del caché anterior
    });
    
  });
}
```

**Esfuerzo**: ~4-6 horas  
**Impacto**: P0 - Previene bugs en producción

---

#### P0.2 - Crear Tabla de Auditoría de Cambios
**Archivo**: `database/migrations/add_pago_audit_log.sql` (NUEVO)

```sql
CREATE TABLE pagos_audit_log (
  id INT PRIMARY KEY AUTO_INCREMENT,
  pago_id INT NOT NULL,
  campo_modificado VARCHAR(50),
  valor_anterior VARCHAR(255),
  valor_nuevo VARCHAR(255),
  usuario_id INT,
  accion VARCHAR(50), -- 'insert', 'update', 'delete'
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (pago_id) REFERENCES pagos_membresias(id) ON DELETE CASCADE,
  INDEX (pago_id, timestamp)
);
```

**Modificaciones en `pagos_service.dart`**:
```dart
// En registrarPago(), después del INSERT
await _db.query(
  '''
  INSERT INTO pagos_audit_log 
  (pago_id, accion, usuario_id, timestamp)
  VALUES (?, ?, ?, ?)
  ''',
  [pagoId, 'insert', null, DateTime.now()],
);

// En UPDATE de tipo (abono → completo)
await _db.query(
  '''
  INSERT INTO pagos_audit_log 
  (pago_id, campo_modificado, valor_anterior, valor_nuevo, accion, timestamp)
  VALUES (?, ?, ?, ?, ?, ?)
  ''',
  [pagoId, 'tipo', 'abono', 'completo', 'update', DateTime.now()],
);
```

**Esfuerzo**: ~2 horas  
**Impacto**: P0 - Requerido para auditoría/compliance

---

### 🟡 P1: ALTOS

#### P1.1 - Refactorizar Método Redundante
**Archivo**: `lib/services/pagos_service.dart`

**Antes**:
```dart
// registrarPago() llama a _extenderMembresia()
// LUEGO el BLoC llama a verificarYAplicarEstadoAbono()
// Ambas actualizar status='activo' (DUPLICADO)
```

**Después**:
```dart
// Opción A: Eliminar verificarYAplicarEstadoAbono() (recomendado)
@Deprecated('registrarPago() ya maneja esto automáticamente')
Future<bool> verificarYAplicarEstadoAbono({...}) { ... }

// Opción B: Integrar lógica en registrarPago()
// Si saldo_completado → _extenderMembresia() ya hace status='activo'
// No necesita llamada separada
```

**Cambio en BLoC**:
```dart
// Antes:
await _service.verificarYAplicarEstadoAbono(...);
await _service.registrarPago(...);

// Después:
final resultado = await _service.registrarPago(...);
// TODO: verificarYAplicarEstadoAbono() ya no es necesario
```

**Esfuerzo**: ~1 hora  
**Impacto**: Reduce complejidad, elimina llamadas innecesarias

---

#### P1.2 - Crear Validador Reutilizable de Plan
**Archivo**: `lib/services/pagos_service.dart`

```dart
/// Valida que el asesorado tenga plan activo con costo válido
/// Lanza excepción con mensaje claro si falta
Future<Map<String, dynamic>> _validarYObtenerPlan(int asesoradoId) async {
  final datos = await _obtenerDatosAsesorado(asesoradoId);
  
  if (datos == null) {
    throw Exception(
      'Asesorado $asesoradoId no existe',
    );
  }
  
  final planId = datos['plan_id'] as int?;
  if (planId == null) {
    throw Exception(
      'Asesorado $asesoradoId no tiene plan asignado. '
      'Asigna un plan en el módulo de asesorados.',
    );
  }
  
  final costoPlan = _toDouble(datos['plan_costo']);
  if (costoPlan <= 0) {
    throw Exception(
      'El plan ${datos['plan_nombre']} tiene costo inválido (\$$costoPlan). '
      'Verifica la configuración del plan.',
    );
  }
  
  return {
    'plan_id': planId,
    'plan_costo': costoPlan,
    'plan_nombre': datos['plan_nombre'],
  };
}

// Uso en registrarPago():
final plan = await _validarYObtenerPlan(asesoradoId);
final costoPlan = plan['plan_costo'] as double;
```

**Esfuerzo**: ~1 hora  
**Impacto**: Mejor UX (mensajes de error claros), reutilizable

---

#### P1.3 - Crear Suite de Tests E2E con BD Real
**Archivo**: `test/e2e/pagos_real_db_e2e_test.dart` (NUEVO)

```dart
void main() {
  group('Pagos E2E - Real Database Workflow', () {
    
    test('Flujo completo: crear asesorado → asignar plan → pagar → extender', () async {
      // 1. Crear asesorado
      // 2. Asignar plan (5000/mes)
      // 3. Registrar abono 3000
      // 4. Verificar: saldo=2000, tipo=abono, estado=pendiente
      // 5. Registrar abono 2000
      // 6. Verificar: saldo=0, tipo=completo, estado=activo, fecha extendida
      // 7. Siguiente período creado automáticamente
    });
    
    test('Manejo de error: pagar sin plan asignado', () async {
      // Crear asesorado SIN plan
      // Intentar registrar pago
      // Verify: excepción con mensaje claro
    });
    
    test('Race condition: dos pagos simultáneos', () async {
      // Usar Future.wait() para registrar dos pagos en paralelo
      // Verify: ambos se procesan, saldo se calcula correctamente
    });
    
  });
}
```

**Esfuerzo**: ~3 horas  
**Impacto**: Valida flujos realistas, previene regresiones

---

### 🟢 P2: MEDIOS

#### P2.1 - Mejorar Logging de Transacciones
**Archivo**: `lib/services/pagos_service.dart`

```dart
// Crear método helper para logs estructurados
void _logTransaccion({
  required String accion, // 'insert_pago', 'extend_membresia', etc.
  required int asesoradoId,
  Map<String, dynamic>? datos,
  String? nota,
}) {
  if (kDebugMode) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint(
      '[$timestamp] [TRANSACCION] Acción=$accion, '
      'Asesorado=$asesoradoId, Datos=${jsonEncode(datos)}, '
      'Nota=$nota',
    );
  }
  
  // TODO: Enviar a servidor de logs centralizados (Firebase, etc.)
}
```

**Esfuerzo**: ~1 hora  
**Impacto**: P2 - Facilita debugging en producción

---

#### P2.2 - Cachear Períodos Disponibles
**Archivo**: `lib/services/pagos_service.dart`

```dart
// Agregar a caché granular
final Map<int, (List<String>, DateTime)> _periodosCache = {};
static const Duration _periodosCacheDuration = Duration(minutes: 10);

// Modificar obtenerTodosPeriodos():
Future<List<String>> obtenerTodosPeriodos(int asesoradoId) async {
  final now = DateTime.now();
  
  if (_periodosCache.containsKey(asesoradoId)) {
    final (cached, timestamp) = _periodosCache[asesoradoId]!;
    if (now.difference(timestamp) < _periodosCacheDuration) {
      return cached;
    }
  }
  
  final periodos = await _db.query(...);
  _periodosCache[asesoradoId] = (periodos, now);
  return periodos;
}

// Invalidar en registrarPago():
_periodosCache.remove(asesoradoId);
```

**Esfuerzo**: ~1 hora  
**Impacto**: P2 - Reduce consultas, mejora performance UI

---

## 📅 Roadmap Recomendado

```
Semana 1:
  - P0.1: Crear tests integración BD real (4 horas)
  - P0.2: Tabla auditoría + inserts en pagos_service (2 horas)

Semana 2:
  - P1.1: Refactorizar método redundante (1 hora)
  - P1.2: Validador de plan reutilizable (1 hora)
  - P1.3: Suite E2E completa (3 horas)

Semana 3:
  - P2.1: Logging estructurado (1 hora)
  - P2.2: Cachear períodos (1 hora)
  - Testing final + ajustes (2 horas)

Total: ~15-18 horas de desarrollo
```

---

## 🎯 Métricas de Éxito

| Métrica | Antes | Objetivo |
|---|---|---|
| Cobertura de tests pagos | 10% | >80% |
| Mensajes de error genéricos | 60% | 10% |
| Métodos redundantes | 3 | 0 |
| Queries a BD por operación | 3-6 | 1-2 (con caché) |
| Latencia promedio UI | 800ms | <300ms |

---

**FIN DEL PLAN**
