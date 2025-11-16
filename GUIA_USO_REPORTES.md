# 📖 GUÍA DE USO - MÓDULO DE REPORTES MEJORADO

**Versión:** 2.0 (Auditada y Refactorizada)  
**Fecha:** 10 de noviembre de 2025  
**Estado:** ✅ Listo para Producción  

---

## 🎯 DESCRIPCIÓN GENERAL

El módulo de reportes proporciona análisis completos sobre:
- 💰 **Pagos:** Ingresos, deudores, estado de membresías
- 🏋️ **Rutinas:** Adherencia, ejercicios completados, progreso
- 📊 **Métricas:** Evolución de peso, grasa corporal, IMC
- 📝 **Bitácora:** Notas, seguimiento de objetivos, anotaciones

---

## 🚀 CÓMO USAR

### 1. Acceder a Reportes
```dart
ReportsScreen(coachId: coachId)
```

### 2. Seleccionar Rango de Fechas

**Características:**
- ✅ Validación automática: Fecha final > fecha inicial
- ✅ Límite máximo: 365 días
- ✅ Feedback visual: Mensajes de error claros

**Ejemplo de error:**
```
❌ "La fecha final debe ser posterior a la fecha inicial"
❌ "El rango no puede exceder 365 días"
```

### 3. Seleccionar Reporte (Tab)

**Disponibles:**
- 📄 **Pagos** - Ingresos y deudores
- 🏋️ **Rutinas** - Adherencia y progreso
- 📊 **Métricas** - Evolución física
- 📝 **Bitácora** - Notas y objetivos

### 4. Filtro Opcional: Seleccionar Asesorado

Algunos reportes permiten filtrar por un asesorado específico.

### 5. Exportar Resultado

**Formatos disponibles:**
- 📕 **PDF** - Con gráficos y tablas
- 📗 **Excel** - Para análisis en hoja de cálculo

---

## ⚡ CARACTERÍSTICAS DE RENDIMIENTO

### Caché Automático
```
✅ Datos cacheados por 15 minutos
✅ Evita queries repetidas a BD
✅ Se limpia automáticamente al cambiar filtros
```

### Validación de Entrada
```
✅ Fechas: Rango máximo 365 días
✅ Asesorados: Validados contra BD
✅ Feedback: Inmediato y visual
```

### Feedback Visual
```
✅ Loader mientras carga
✅ Mensajes de error claros
✅ Estado vacío informativo
✅ Confirmación de exportación
```

---

## 📊 GUÍA POR REPORTE

### 💰 REPORTE DE PAGOS

**Muestra:**
- Total de ingresos en el período
- Pagos completos vs abonos parciales
- Ingresos por mes (gráfico)
- Lista de asesorados deudores con monto

**Ejemplo:**
```
Período: 01/10/2025 - 31/10/2025

Resumen:
- Ingresos Totales: $5,000.00
- Pagos Completos: $3,500.00
- Abonos Parciales: $1,500.00
- Asesorados Deudores: 3

Deudores:
- Juan López: $500.00 (deuda)
- María García: $250.00
- Carlos Ruiz: $750.00
```

**Casos de uso:**
- Seguimiento de flujo de caja
- Identificar deudores
- Análisis de membresías

---

### 🏋️ REPORTE DE RUTINAS

**Muestra:**
- Top 10 rutinas más usadas
- Progreso de series completadas
- Adherencia por asesorado

**Ejemplo:**
```
Período: 01/10/2025 - 31/10/2025

Rutinas Más Usadas:
1. Pecho Completo - 12 asignaciones, 95% adherencia
2. Espalda Media - 10 asignaciones, 80% adherencia
3. Piernas - 9 asignaciones, 100% adherencia

Progreso por Asesorado:
- Juan López (Pecho): 24/32 series (75%)
- Juan López (Espalda): 16/20 series (80%)
- María García (Piernas): 18/18 series (100%)
```

**Casos de uso:**
- Identificar rutinas populares
- Monitorear adherencia
- Personalizar entrenamientos

---

### 📊 REPORTE DE MÉTRICAS

**Muestra:**
- Evolución de peso, grasa corporal, IMC
- Cambios significativos (>2%)
- Resumen por asesorado

**Ejemplo:**
```
Período: 01/10/2025 - 31/10/2025

Cambios Significativos:
- Juan López: Peso ↓ 3kg (-5.2%) [Excelente]
- María García: Grasa ↓ 2% (-8.1%) [Excelente]
- Carlos Ruiz: Sin cambios significativos

Resumen Juan López:
- Peso: 57kg → 54kg (cambio: -3kg)
- Grasa: 28% → 25% (cambio: -3%)
- IMC: 22.3 → 21.2
- Total mediciones: 4
```

**Casos de uso:**
- Medir progreso físico
- Motivar asesorados
- Ajustar planes

---

### 📝 REPORTE DE BITÁCORA

**Muestra:**
- Total de notas registradas
- Notas prioritarias vs normales
- Rastreo de objetivos mencionados

**Ejemplo:**
```
Período: 01/10/2025 - 31/10/2025

Resumen:
- Total Notas: 24
- Notas Prioritarias: 5
- Por Asesorado:
  * Juan López: 8 notas
  * María García: 10 notas
  * Carlos Ruiz: 6 notas

Objetivos Rastreados:
- "Objetivo" (7 menciones) - últimas desde 01/10 a 25/10
- "Progreso" (5 menciones) - últimas desde 05/10 a 28/10
- "Meta" (3 menciones) - últimas desde 15/10 a 20/10
```

**Casos de uso:**
- Revisar notas por período
- Rastrear objetivos
- Identificar asesorados prioritarios

---

## 🔧 MANEJO DE ERRORES

### Errores Comunes

#### 1. "La fecha final debe ser posterior a la fecha inicial"
```
Causa: Intentaste seleccionar una fecha final anterior a la inicial
Solución: Verifica el orden de las fechas
```

#### 2. "El rango no puede exceder 365 días"
```
Causa: El período seleccionado es mayor a 1 año
Solución: Acorta el rango de fechas
```

#### 3. "Error al cargar reporte de pagos"
```
Causa: Problema temporal con la BD o red
Solución: Intenta nuevamente, contacta soporte si persiste
```

#### 4. "No hay datos para exportar"
```
Causa: El reporte está vacío (sin datos en período)
Solución: Verifica que existan datos en el rango de fechas
```

---

## 💡 TIPS Y TRUCOS

### 1. Optimizar Búsquedas
```
✅ Usar períodos cortos (1-3 meses) para búsquedas rápidas
✅ Filtrar por asesorado si necesitas detalles
❌ Evitar períodos muy largos (>6 meses) sin necesidad
```

### 2. Exportar para Análisis
```
✅ PDF: Para presentaciones y distribución
✅ Excel: Para análisis detallados y gráficos propios
✅ Exporta regularmente para crear históricos
```

### 3. Monitorear Métricas
```
✅ Revisa cambios >2% como significativos
✅ Busca tendencias en múltiples asesorados
✅ Compara períodos para ver evolución
```

### 4. Gestionar Deudores
```
✅ Revisa lista de deudores semanalmente
✅ Usa reporte para cobros y seguimiento
✅ Registra notas en bitácora sobre deudores
```

---

## 🎯 CASOS DE USO COMUNES

### Caso 1: Revisar Ingresos Mensuales
```
1. Abre Reportes → Tab "Pagos"
2. Selecciona fechas del mes (01 al 30)
3. Visualiza gráfico de ingresos
4. Identifica deudores en tabla
5. Exporta a Excel para contabilidad
```

### Caso 2: Monitorear Progreso de Asesorado
```
1. Abre Reportes
2. Selecciona asesorado específico
3. Revisa tab "Rutinas" (adherencia)
4. Revisa tab "Métricas" (evolución física)
5. Exporta a PDF para mostrar al asesorado
```

### Caso 3: Evaluar Efectividad de Rutinas
```
1. Abre Reportes → Tab "Rutinas"
2. Visualiza Top 10 rutinas más usadas
3. Identifica las de menor adherencia
4. Ajusta planes basándote en resultados
```

### Caso 4: Hacer Seguimiento de Objetivos
```
1. Abre Reportes → Tab "Bitácora"
2. Revisa notas del período
3. Identifica objetivos mencionados
4. Contabiliza progreso en objetivos
```

---

## 🔐 CONSIDERACIONES DE SEGURIDAD

### Datos Visibles
```
✅ Solo ves datos de TUS asesorados
✅ Filtros automáticos por coach_id
✅ Notas privadas no se exponen
```

### Exportaciones
```
✅ Archivos generados localmente
✅ No se guardan en servidores
✅ Usa rutas seguras del dispositivo
```

### Auditoría
```
✅ Todas las queries incluyen coach_id
✅ Manejo seguro de fechas
✅ Validación de entrada en UI
```

---

## 🐛 REPORTAR PROBLEMAS

Si encuentras un bug:

1. **Anota los pasos para reproducirlo**
2. **Documenta la fecha/hora**
3. **Incluye el período de reporte**
4. **Adjunta un screenshot si es posible**
5. **Contacta al equipo de soporte**

---

## 📈 MEJORAS FUTURAS

Estas características pueden agregarse en versiones futuras:

- [ ] Reportes comparativos (mes vs mes)
- [ ] Alertas automáticas de deudores
- [ ] Exportación a Google Sheets
- [ ] Reportes por grupo de asesorados
- [ ] Predicciones basadas en tendencias
- [ ] Integración con invoice/facturación

---

## 📞 AYUDA Y SOPORTE

**¿Tienes preguntas?**

Consulta:
1. Este documento
2. `AUDITORIA_REPORTES_COMPLETADA.md` (detalles técnicos)
3. `CAMBIOS_RESUMIDOS.md` (cambios implementados)

**¿Necesitas help técnico?**

Revisa los logs:
- Abre DevTools → Console
- Busca líneas con "ReportsService"
- El log mostrará qué pasó

---

**Última actualización:** 10 de noviembre de 2025  
**Versión:** 2.0  
**Estado:** ✅ Producción  

Disfruta del módulo de reportes mejorado y optimizado! 🚀
