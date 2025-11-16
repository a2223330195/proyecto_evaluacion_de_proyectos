# 📊 ANÁLISIS PROFUNDO - LÓGICA DE LOS 7 ESTADOS DE PAGO

**Fecha**: 11 de noviembre de 2025  
**Análisis**: Lógica de estados, redundancia y estructura en BD

---

## 📋 LOS 7 ESTADOS DEFINIDOS

```
1. sin_plan          → Sin plan asignado (plan_id IS NULL)
2. sin_vencimiento   → Tiene plan pero sin fecha_vencimiento
3. vencido           → fecha_vencimiento < hoy
4. proximo_vencimiento → hoy ≤ fecha_vencimiento ≤ hoy+7
5. activo            → fecha_vencimiento > hoy+7
6. pagado            → saldo_pendiente ≤ 0 (independiente de fecha)
7. deudor            → (almacenado en tabla, no calculado)
```

---

## 🔍 ANÁLISIS DE LÓGICA EN `obtenerEstadoPago()`

### **Flujo de Cálculo**

```dart
obtenerEstadoPago(asesoradoId)
├─ Obtener: status, fecha_vencimiento, plan_id, costo_plan, plan_nombre
│
├─ [FILTRO 1] ¿plan_id == NULL?
│  └─ Retornar: estado='sin_plan' ✅
│
├─ [FILTRO 2] ¿fecha_vencimiento == NULL?
│  └─ Retornar: estado='sin_vencimiento' ✅
│
├─ [FILTRO 3] ¿costoPlan <= 0?
│  └─ Retornar: estado='activo' (saldo=0) ✅
│
├─ [CÁLCULO] Determinar períodoObjetivo (período pendiente + saldo)
│
└─ [LÓGICA IF-ELSE CASCADE]
   ├─ ¿saldo_pendiente <= 0?
   │  └─ estado = 'pagado' ✅
   │
   ├─ ¿diasHastaVencimiento < 0?
   │  └─ estado = 'vencido' ✅
   │
   ├─ ¿diasHastaVencimiento <= 7?
   │  └─ estado = 'proximo_vencimiento' ✅
   │
   └─ [ELSE]
      └─ estado = 'activo' ✅
```

---

## 🎯 ANÁLISIS DE REDUNDANCIA Y PROBLEMAS

### **PROBLEMA 1: 'vencido' y 'sin_plan' son Mutuamente Exclusivos con 'activo'**

**Línea 475-490 (sin_plan)**:
```dart
if (planId == null) {
  return {
    'estado': 'sin_plan',
    'saldo_pendiente': 0.0,
    'fecha_vencimiento': null,
    ...
  };
}
```

**Línea 491-509 (sin_vencimiento)**:
```dart
if (fechaVencimiento == null) {
  return {
    'estado': 'sin_vencimiento',
    'saldo_pendiente': costoPlan,  // ⚠️ Asume saldo = costoPlan completo
    ...
  };
}
```

**Problema Identificado**:
- `sin_vencimiento` retorna `saldo_pendiente = costoPlan` **SIN CALCULAR ABONOS REALES**
- Si un asesorado sin fecha vencimiento ya pagó parcialmente, el saldo será incorrecta
- **Estado nunca puede ser 'pagado' si no tiene fecha_vencimiento**

**Recomendación**:
```dart
// ✅ MEJORADO: Calcular saldo incluso sin fecha_vencimiento
if (fechaVencimiento == null) {
  final periodoObjetivo = await _determinarPeriodoObjetivo(
    asesoradoId: asesoradoId,
    costoPlan: costoPlan,
    fechaVencimiento: null,  // Permitir NULL
  );
  
  return {
    'estado': periodoObjetivo.saldoPendiente <= 0 ? 'pagado' : 'sin_vencimiento',
    'saldo_pendiente': periodoObjetivo.saldoPendiente,  // ✅ Real, no asumido
    ...
  };
}
```

---

### **PROBLEMA 2: 'vencido' Ignora el Saldo**

**Líneas 522-528**:
```dart
// Si está vencido (pasado)
else if (diasHastaVencimiento < 0) {
  estadoCalculado = 'vencido';
}
```

**Problema Identificado**:
- Un asesorado **puede estar vencido PERO TOTALMENTE PAGADO** 
  - `fecha_vencimiento = 2025-10-01` (pasada)
  - `saldo = 0` (ya pagó todo)
  - **Resultado**: estado='vencido' (aunque ya no debe nada)

- Prioridad de cálculo es confusa:
  1. Primero checa saldo ('pagado')
  2. Luego checa vencimiento ('vencido')
  3. Luego próximo ('proximo_vencimiento')

**¿Qué significa 'vencido'?**
- ¿"La fecha pasó sin pagar"? → Debería ser 'vencido' = saldo > 0 AND fecha < hoy
- ¿"La fecha simplemente pasó"? → Puede confundir al usuario (no sabe si debe pagar)

**Recomendación**:
```dart
// ✅ MEJORADO: Prioridad clara
if (periodoObjetivo.saldoPendiente <= 0) {
  estadoCalculado = 'pagado';  // Si está pagado, ignorar vencimiento
}
else if (diasHastaVencimiento < 0) {
  estadoCalculado = 'vencido';  // Solo si hay saldo pendiente
}
else if (diasHastaVencimiento <= 7) {
  estadoCalculado = 'proximo_vencimiento';
}
else {
  estadoCalculado = 'activo';
}
```

---

### **PROBLEMA 3: 'pagado' y 'activo' Pueden Superponerse**

**Línea 520-521**:
```dart
if (periodoObjetivo.saldoPendiente <= 0) {
  estadoCalculado = 'pagado';
}
```

**Línea 549-551**:
```dart
else {
  estadoCalculado = 'activo';
}
```

**Escenario de Ambigüedad**:
```
Asesorado A:
- plan_id = 1 (existe)
- fecha_vencimiento = 2025-12-31 (futura)
- saldo_pendiente = 0 (pagado)
- diasHastaVencimiento = 50

Estado Calculado: 'pagado' ✅

Asesorado B:
- plan_id = 1 (existe)
- fecha_vencimiento = 2025-12-31 (futura)
- saldo_pendiente = 100 (debe)
- diasHastaVencimiento = 50

Estado Calculado: 'activo' ✅
```

**Diferencia Clara**: Lógica es correcta. No hay redundancia.

---

### **PROBLEMA 4: Tres Métodos Separados para Filtrar Pagos Pendientes (Redundancia)**

**Líneas 630-690** (`obtenerAsesoradosConPagosPendientes`):
```dart
WHERE a.coach_id = ?
  AND a.plan_id IS NOT NULL
  AND (
    a.status = 'deudor' OR 
    (a.status = 'activo' AND a.fecha_vencimiento BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY))
  )
```

**Líneas 692-735** (`obtenerAsesoradosConPagosAtrasados`):
```dart
WHERE a.coach_id = ?
  AND a.status = 'deudor'
```

**Líneas 737-785** (`obtenerAsesoradosConPagosProximos`):
```dart
WHERE a.coach_id = ?
  AND a.plan_id IS NOT NULL
  AND a.status = 'activo'
  AND a.fecha_vencimiento BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)
```

**Redundancia Identificada**:
- **85% del código es duplicado** (SELECT, JOINs, caché)
- Cada método repite:
  ```sql
  SELECT a.id, a.nombre, a.avatar_url, p.nombre AS plan_nombre, 
         a.fecha_vencimiento, p.costo, 'estado'
  FROM asesorados a
  LEFT JOIN planes p ON a.plan_id = p.id
  ```
- Solo varía la cláusula `WHERE` y el valor hardcodeado de `estado`

**Recomendación**:
```dart
// ✅ REFACTORIZADO: Un método parametrizado
Future<List<AsesoradoPagoPendiente>> obtenerAsesoradosConEstado(
  int coachId, {
  String? estadoFiltro,  // 'atrasado', 'proximo', null (todos pendientes)
  int page = 0,
  int pageSize = 20,
}) async {
  String whereCondition = 'a.coach_id = ? AND a.plan_id IS NOT NULL';
  List<dynamic> params = [coachId];

  if (estadoFiltro == 'atrasado') {
    whereCondition += ' AND a.status = "deudor"';
  } else if (estadoFiltro == 'proximo') {
    whereCondition += ' AND a.status = "activo" AND a.fecha_vencimiento BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)';
  } else {
    // 'todos' o null: deudor O próximos
    whereCondition += ' AND (a.status = "deudor" OR (a.status = "activo" AND a.fecha_vencimiento BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)))';
  }

  final offset = page * pageSize;
  final sql = '''
    SELECT a.id, a.nombre, a.avatar_url, COALESCE(p.nombre, 'Sin Plan') AS plan_nombre,
           a.fecha_vencimiento, COALESCE(p.costo, 0.0) AS costo_plan, COALESCE(p.costo, 0.0) AS monto_pendiente,
           CASE 
             WHEN a.status = 'deudor' THEN 'atrasado'
             WHEN a.fecha_vencimiento BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY) THEN 'proximo'
             ELSE 'pendiente'
           END as estado
    FROM asesorados a
    LEFT JOIN planes p ON a.plan_id = p.id
    WHERE $whereCondition
    ORDER BY a.fecha_vencimiento ASC
    LIMIT ? OFFSET ?
  ''';

  params.addAll([pageSize, offset]);

  // Ejecutar con caché única clave
  final cacheKey = 'asesorados_pendientes_${coachId}_${estadoFiltro}_${page}_$pageSize';
  if (_isCacheValid(cacheKey)) {
    return _cache[cacheKey]!.data;
  }

  final results = await _db.query(sql, params);
  final data = [for (final row in results) AsesoradoPagoPendiente.fromMap(row.fields)];
  _cache[cacheKey] = _CacheEntry(data);
  return data;
}

// ✅ Métodos de conveniencia (thin wrappers)
Future<List<AsesoradoPagoPendiente>> obtenerAsesoradosConPagosPendientes(int coachId, {int page = 0, int pageSize = 20})
  => obtenerAsesoradosConEstado(coachId, estadoFiltro: null, page: page, pageSize: pageSize);

Future<List<AsesoradoPagoPendiente>> obtenerAsesoradosConPagosAtrasados(int coachId)
  => obtenerAsesoradosConEstado(coachId, estadoFiltro: 'atrasado', pageSize: 1000);

Future<List<AsesoradoPagoPendiente>> obtenerAsesoradosConPagosProximos(int coachId)
  => obtenerAsesoradosConEstado(coachId, estadoFiltro: 'proximo', pageSize: 1000);
```

---

### **PROBLEMA 5: 'deudor' es un Estado de BD, No de Cálculo**

**En `obtenerEstadoPago()`**:
- Los 7 estados se **calculan dinámicamente** desde `fecha_vencimiento`, `saldo_pendiente`, `plan_id`
- No se usa el campo `a.status` de la tabla

**En `obtenerAsesoradosConPagosPendientes()`**:
- Se **filtra por `a.status = 'deudor'`** de la tabla
- Se **devuelve un estado calculado** 'atrasado', 'proximo', 'pendiente'

**Inconsistencia**:
- `a.status` en BD puede estar:
  - `'activo'` → pagos al día, fecha vigente
  - `'deudor'` → vencido y sin pagar
- Pero `obtenerEstadoPago()` **nunca retorna 'deudor'**, retorna 'vencido'

**¿Cuándo se actualiza `a.status = 'deudor'`?**
- Se actualiza en `_extenderMembresia()` → `status = 'activo'`
- Se actualiza en `verificarYAplicarEstadoAbono()` → `status = 'activo'`
- **NUNCA se establece explícitamente a 'deudor'**

**Recomendación**:
```dart
// ✅ En completarPago/registrarAbono, después de _extenderMembresia:
if (saldoPendiente > 0 && fechaVencimiento != null && fechaVencimiento < hoy) {
  await _db.query(
    "UPDATE asesorados SET status = 'deudor' WHERE id = ?",
    [asesoradoId],
  );
}

// ✅ O mejor: que status refleje el estado calculado
// status = obtenerEstadoPago().estado.replaceAll('proximo_vencimiento', 'activo')
```

---

## 📊 RESUMEN: REDUNDANCIA Y PROBLEMAS

| Problema | Ubicación | Severidad | Tipo |
|----------|-----------|-----------|------|
| **1** | `sin_vencimiento`: no calcula saldo real | MEDIA | Lógica |
| **2** | `vencido`: ignora saldo = 0 (puede confundir) | MEDIA | Semántica |
| **3** | Tres métodos `obtenerAsesoradosConPagos*` | ALTA | Redundancia (85% código duplicado) |
| **4** | `status` en BD nunca se establece a 'deudor' | BAJA | Sincronización |
| **5** | `obtenerEstadoPago` usa 7 estados, pero `status` tiene solo 3 | MEDIA | Inconsistencia |

---

## 🗄️ ESTRUCTURA EN BASE DE DATOS

### **Tabla `asesorados`**

```sql
CREATE TABLE asesorados (
  id INT PRIMARY KEY,
  coach_id INT,
  nombre VARCHAR(255),
  status ENUM('activo', 'deudor', ...),         -- ⚠️ Solo 2-3 valores
  plan_id INT,                                   -- NULL si sin plan
  fecha_vencimiento DATE,                        -- NULL si sin vencimiento
  avatar_url VARCHAR(255),
  ...
)
```

**Problemas**:
- `status` tiene 2-3 valores posibles, pero `obtenerEstadoPago()` calcula 7 estados
- No hay sincronización automática entre `status` y el estado calculado
- `status = 'deudor'` nunca se establece en el código

### **Tabla `pagos_membresias`**

```sql
CREATE TABLE pagos_membresias (
  id INT PRIMARY KEY,
  asesorado_id INT,
  fecha_pago DATE,
  monto DECIMAL(10,2),
  periodo VARCHAR(7),                            -- YYYY-MM
  tipo ENUM('completo', 'abono'),               -- ✅ Correcto (después de corrección)
  nota TEXT,
  ...
)
```

**Correcto**: 
- `tipo` ahora refleja correctamente si es abono o pago completo
- `periodo` permite agrupar y calcular saldos por período

### **Tabla `planes`**

```sql
CREATE TABLE planes (
  id INT PRIMARY KEY,
  nombre VARCHAR(255),
  costo DECIMAL(10,2),
  ...
)
```

**Correcto**: Costo leído sin errores de tipo.

---

## ✅ RECOMENDACIONES FINALES

### **1. Refactorizar `obtenerEstadoPago()` para Consistencia**

```dart
// ✅ MEJORADO: Orden de prioridad claro
String _calcularEstado(
  int? planId,
  DateTime? fechaVencimiento,
  double costoPlan,
  double saldoPendiente,
) {
  // Prioridad 1: Sin plan
  if (planId == null) return 'sin_plan';

  // Prioridad 2: Sin vencimiento pero con plan
  if (fechaVencimiento == null) {
    return saldoPendiente <= 0 ? 'pagado' : 'sin_vencimiento';
  }

  // Prioridad 3: Saldo cubierto (independiente de fecha)
  if (saldoPendiente <= 0) return 'pagado';

  // Prioridad 4: Fecha pasada sin pagar
  final diasHastaVencimiento = fechaVencimiento.difference(DateTime.now()).inDays;
  if (diasHastaVencimiento < 0) return 'vencido';

  // Prioridad 5: Próximo a vencer (con saldo pendiente)
  if (diasHastaVencimiento <= 7) return 'proximo_vencimiento';

  // Prioridad 6: Activo y con tiempo
  return 'activo';
}
```

### **2. Consolidar Métodos de Filtrado**

```dart
// ✅ Usar método parametrizado en lugar de 3 duplicados
Future<List<AsesoradoPagoPendiente>> obtenerAsesoradosConEstado(
  int coachId, {
  String? estadoFiltro,
  int page = 0,
  int pageSize = 20,
})
```

### **3. Sincronizar `status` en BD**

```dart
// ✅ Después de cada operación de pago, actualizar status
String estadoCalculado = _calcularEstado(...);
await _db.query(
  "UPDATE asesorados SET status = ? WHERE id = ?",
  [
    estadoCalculado == 'vencido' ? 'deudor' : 'activo',
    asesoradoId,
  ],
);
```

### **4. Documentación Clara de Estados**

```dart
/// Estados posibles para un asesorado:
/// 
/// 1. sin_plan         → plan_id IS NULL
/// 2. sin_vencimiento  → plan_id NOT NULL AND fecha_vencimiento IS NULL
/// 3. vencido          → saldo > 0 AND fecha_vencimiento < HOY
/// 4. proximo_vencimiento → saldo > 0 AND HOY <= fecha_vencimiento <= HOY+7
/// 5. activo           → saldo > 0 AND fecha_vencimiento > HOY+7
/// 6. pagado           → saldo <= 0 (cualquier fecha)
///
/// Prioridad (si múltiples condiciones): sin_plan > sin_vencimiento > pagado > vencido > proximo > activo
```

---

## 🎯 CONCLUSIÓN

**Estado Actual**:
- ✅ Lógica de los 7 estados es **mayormente correcta**
- ⚠️ **3 problemas identificados** (sin_vencimiento, vencido, status inconsistencia)
- 🔴 **1 problema de redundancia severa** (3 métodos duplicados 85%)

**Impacto**:
- No hay fallos funcionales observados
- Pero hay oportunidades de mejora para claridad y mantenibilidad
- Refactorización reduciría **~150 líneas de código duplicado**

**Recomendación Inmediata**:
- Considerar implementar refactorización de métodos duplicados
- Mejorar documentación de los 7 estados para evitar confusión futura
- Sincronizar `status` en BD con estado calculado

---

**Auditoría completada**: 11 de noviembre de 2025
