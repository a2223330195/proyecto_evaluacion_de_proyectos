
-- ========================================
-- COACHHUB DATABASE SCHEMA
-- VERSIÓN: 2.0 COMPLETA CON MEDICIONES AMPLIADAS
-- FECHA: 2025-10-28
-- DESCRIPCIÓN: Schema completo incluyendo mediciones, nutricionales, pagos, rutinas, agenda
-- IMPORTANTE: Este script borra TODO y empieza de cero
-- ========================================

-- 1. ELIMINAR LA BASE DE DATOS ANTERIOR (REINICIO TOTAL)
-- ⚠️  ESTO BORRA TODO - La app reconstruye desde cero
DROP DATABASE IF EXISTS coachhub_db;

-- 2. Crear la base de datos
CREATE DATABASE coachhub_db
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Usar la base de datos
USE coachhub_db;

-- 3. Tabla de Coaches (Usuarios de la App)
-- Almacena la información de inicio de sesión para los entrenadores
CREATE TABLE IF NOT EXISTS coaches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    plan VARCHAR(50) NOT NULL DEFAULT 'Básico',
    profile_picture_url VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Tabla de Planes (NUEVA)
-- Almacena los planes de membresía que el coach ofrece
CREATE TABLE IF NOT EXISTS planes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    costo DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    coach_id INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Semillas de planes por defecto para asegurar opciones mínimas
INSERT INTO planes (nombre, costo, coach_id)
SELECT 'Básico', 0.00, NULL
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM planes WHERE nombre = 'Básico'
);

INSERT INTO planes (nombre, costo, coach_id)
SELECT 'Premium', 49.99, NULL
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM planes WHERE nombre = 'Premium'
);

-- 5. Tabla de Asesorados
-- Almacena la información de tus clientes (visto en asesorado_model.dart)
CREATE TABLE IF NOT EXISTS asesorados (
    id INT AUTO_INCREMENT PRIMARY KEY,
    coach_id INT NULL,
    nombre VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(255) NULL,
    status ENUM('activo', 'enPausa', 'deudor') NOT NULL DEFAULT 'activo',
    plan_id INT NULL,
    fecha_vencimiento DATE NULL,
    edad INT NULL CHECK (edad >= 1 AND edad <= 120),
    sexo ENUM('Masculino', 'Femenino', 'Otro', 'NoEspecifica') NULL,
    altura_cm DECIMAL(5,2) NULL CHECK (altura_cm >= 50 AND altura_cm <= 250),
    telefono VARCHAR(20) NULL,
    fecha_inicio_programa DATE NULL,
    objetivo_principal TEXT NULL,
    objetivo_secundario TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (plan_id) REFERENCES planes(id) ON DELETE SET NULL,
    FOREIGN KEY (coach_id) REFERENCES coaches(id) ON DELETE SET NULL,
    CONSTRAINT chk_nombre_not_empty CHECK (nombre != ''),
    INDEX idx_asesorado_nombre (nombre),
    INDEX idx_asesorados_coach_id (coach_id)
);

-- NUEVAS TABLAS PARA MÉTRICAS, NUTRICIÓN Y PAGOS

-- Tabla de Mediciones
-- Almacena el historial de métricas de un asesorado
CREATE TABLE IF NOT EXISTS mediciones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    asesorado_id INT NOT NULL,
    fecha_medicion DATE NOT NULL,
    peso DECIMAL(5,2) NULL CHECK (peso IS NULL OR (peso > 0 AND peso <= 500)),
    porcentaje_grasa DECIMAL(4,2) NULL CHECK (porcentaje_grasa IS NULL OR (porcentaje_grasa >= 0 AND porcentaje_grasa <= 100)),
    imc DECIMAL(4,2) NULL CHECK (imc IS NULL OR (imc > 0 AND imc <= 60)),
    masa_muscular DECIMAL(5,2) NULL CHECK (masa_muscular IS NULL OR (masa_muscular > 0 AND masa_muscular <= 200)),
    agua_corporal DECIMAL(4,2) NULL CHECK (agua_corporal IS NULL OR (agua_corporal >= 0 AND agua_corporal <= 100)),
    pecho_cm DECIMAL(5,2) NULL CHECK (pecho_cm IS NULL OR (pecho_cm > 0 AND pecho_cm <= 300)),
    cintura_cm DECIMAL(5,2) NULL CHECK (cintura_cm IS NULL OR (cintura_cm > 0 AND cintura_cm <= 300)),
    cadera_cm DECIMAL(5,2) NULL CHECK (cadera_cm IS NULL OR (cadera_cm > 0 AND cadera_cm <= 300)),
    brazo_izq_cm DECIMAL(5,2) NULL CHECK (brazo_izq_cm IS NULL OR (brazo_izq_cm > 0 AND brazo_izq_cm <= 200)),
    brazo_der_cm DECIMAL(5,2) NULL CHECK (brazo_der_cm IS NULL OR (brazo_der_cm > 0 AND brazo_der_cm <= 200)),
    pierna_izq_cm DECIMAL(5,2) NULL CHECK (pierna_izq_cm IS NULL OR (pierna_izq_cm > 0 AND pierna_izq_cm <= 300)),
    pierna_der_cm DECIMAL(5,2) NULL CHECK (pierna_der_cm IS NULL OR (pierna_der_cm > 0 AND pierna_der_cm <= 300)),
    pantorrilla_izq_cm DECIMAL(5,2) NULL CHECK (pantorrilla_izq_cm IS NULL OR (pantorrilla_izq_cm > 0 AND pantorrilla_izq_cm <= 200)),
    pantorrilla_der_cm DECIMAL(5,2) NULL CHECK (pantorrilla_der_cm IS NULL OR (pantorrilla_der_cm > 0 AND pantorrilla_der_cm <= 200)),
    frecuencia_cardiaca DECIMAL(5,2) NULL CHECK (frecuencia_cardiaca IS NULL OR (frecuencia_cardiaca > 0 AND frecuencia_cardiaca <= 220)),
    record_resistencia DECIMAL(5,2) NULL CHECK (record_resistencia IS NULL OR (record_resistencia > 0 AND record_resistencia <= 500)),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (asesorado_id) REFERENCES asesorados(id) ON DELETE CASCADE
    -- Nota: Validación de fecha no futura debe hacerse en la aplicación
    -- MySQL no permite funciones como CURDATE() en CHECK constraints
);

-- Tabla de Planes Nutricionales
-- Almacena los planes de nutrición asignados a un asesorado
CREATE TABLE IF NOT EXISTS planes_nutricionales (
    id INT AUTO_INCREMENT PRIMARY KEY,
    asesorado_id INT NOT NULL,
    nombre_plan VARCHAR(255) NOT NULL,
    calorias_diarias INT NULL CHECK (calorias_diarias IS NULL OR (calorias_diarias >= 800 AND calorias_diarias <= 10000)),
    proteinas_gr INT NULL CHECK (proteinas_gr IS NULL OR (proteinas_gr >= 0 AND proteinas_gr <= 500)),
    grasas_gr INT NULL CHECK (grasas_gr IS NULL OR (grasas_gr >= 0 AND grasas_gr <= 500)),
    carbos_gr INT NULL CHECK (carbos_gr IS NULL OR (carbos_gr >= 0 AND carbos_gr <= 1000)),
    recomendaciones TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (asesorado_id) REFERENCES asesorados(id) ON DELETE CASCADE,
    CONSTRAINT chk_nombre_plan_not_empty CHECK (nombre_plan != '')
);

-- Tabla de Pagos de Membresías
-- Almacena el historial de pagos y el estado de la membresía
CREATE TABLE IF NOT EXISTS pagos_membresias (
    id INT AUTO_INCREMENT PRIMARY KEY,
    asesorado_id INT NOT NULL,
    fecha_pago DATE NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    periodo VARCHAR(7) NULL COMMENT 'Periodo de pago YYYY-MM',
    tipo ENUM('completo', 'abono') NOT NULL DEFAULT 'completo',
    nota TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (asesorado_id) REFERENCES asesorados(id) ON DELETE CASCADE
);

-- Tabla de Notas (estructura unificada)
-- Centraliza todas las notas de asesorados con soporte para prioridad
CREATE TABLE IF NOT EXISTS notas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    asesorado_id INT NOT NULL,
    contenido TEXT NOT NULL,
    prioritaria BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (asesorado_id) REFERENCES asesorados(id) ON DELETE CASCADE,
    INDEX idx_notas_asesorado (asesorado_id),
    INDEX idx_notas_prioritaria (prioritaria)
);

-- 6. Tabla de Plantillas de Rutinas
-- Esta es tu "Biblioteca de Rutinas" (visto en rutina_model.dart)
-- FASE K: Actualización a categorías por Grupo Muscular (basado en ejercicios_maestro)
CREATE TABLE IF NOT EXISTS rutinas_plantillas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    descripcion TEXT NULL,
    categoria ENUM(
        'abdominales', 'bíceps', 'tríceps', 'espalda_media', 'lats',
        'espalda_baja', 'hombros', 'cuádriceps', 'glúteos', 'isquiotibiales',
        'pecho', 'pantorrillas', 'antebrazos', 'trapecio', 'aductores', 
        'abductores', 'movilidad'
    ) NOT NULL DEFAULT 'pecho',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6.1 Tabla de Lotes de Rutinas Programadas
-- Agrupa un conjunto de asignaciones creadas desde una misma operación
CREATE TABLE IF NOT EXISTS rutina_batches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    asesorado_id INT NOT NULL,
    rutina_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    default_time TIME NULL,
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (asesorado_id) REFERENCES asesorados(id) ON DELETE CASCADE,
    FOREIGN KEY (rutina_id) REFERENCES rutinas_plantillas(id) ON DELETE CASCADE
);

-- 7. Tabla de Ejercicios Maestro (NUEVA)
-- Base de datos maestra de ejercicios con información general
CREATE TABLE IF NOT EXISTS ejercicios_maestro (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL UNIQUE,
    musculo_principal VARCHAR(100),
    equipamiento VARCHAR(100),
    video_url VARCHAR(255) NULL,
    image_url VARCHAR(255) NULL COMMENT 'URL de imagen del ejercicio desde free-exercise-db',
    fuente VARCHAR(100) DEFAULT 'workout.cool',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Tabla de Ejercicios
-- Almacena cada ejercicio individual, vinculado a una plantilla (visto en rutina_model.dart)
-- NOTA: series, repeticiones, indicador_carga son VARCHAR para permitir flexibilidad
-- (ej. "8-12", "Al fallo", "RPE 8", "50kg", etc.)
CREATE TABLE IF NOT EXISTS ejercicios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    plantilla_id INT NOT NULL,
    ejercicio_maestro_id INT NOT NULL,
    series VARCHAR(50) NOT NULL,
    repeticiones VARCHAR(50) NOT NULL,
    indicador_carga VARCHAR(100) NULL COMMENT 'Carga sugerida: "50kg", "RPE 8", etc.',
    descanso VARCHAR(100) NULL,
    notas TEXT NULL,
    orden INT NOT NULL, -- Para mantener el orden de los ejercicios en la rutina
    FOREIGN KEY (plantilla_id) REFERENCES rutinas_plantillas(id)
        ON DELETE CASCADE, -- Si borras una plantilla, se borran sus ejercicios
    FOREIGN KEY (ejercicio_maestro_id) REFERENCES ejercicios_maestro(id)
        ON DELETE CASCADE
);

-- 8. Tabla de Agenda (Asignaciones)
-- Esta es la tabla MÁS IMPORTANTE. Vincula una Plantilla con un Asesorado en una fecha
-- (visto en el diálogo "Asignar" de rutinas_screen.dart y en agenda_card.dart)
CREATE TABLE IF NOT EXISTS asignaciones_agenda (
    id INT AUTO_INCREMENT PRIMARY KEY,
    asesorado_id INT NOT NULL,
    plantilla_id INT NOT NULL,
    batch_id INT NULL,
    fecha_asignada DATE NOT NULL,
    hora_asignada TIME NULL, -- <<< COLUMNA AÑADIDA
    status ENUM('pendiente', 'completada', 'cancelada') NOT NULL DEFAULT 'pendiente',
    notes TEXT NULL COMMENT 'Notas del coach sobre la asignación',
    feedback_asesorado TEXT NULL COMMENT 'Feedback del asesorado sobre cómo le fue (ej: "Completé 3x8", "Muy pesado", etc.)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (asesorado_id) REFERENCES asesorados(id)
        ON DELETE CASCADE, -- Si borras un asesorado, se borran sus asignaciones
    FOREIGN KEY (plantilla_id) REFERENCES rutinas_plantillas(id)
        ON DELETE CASCADE, -- Si borras una plantilla, se borran sus asignaciones
    FOREIGN KEY (batch_id) REFERENCES rutina_batches(id)
        ON DELETE SET NULL
);

-- 9. Tabla de Log de Ejercicios (NUEVA - FASE J)
-- Captura snapshot de los ejercicios planificados en el momento de la asignación
-- Esto previene que cambios posteriores en la plantilla afecten registros históricos
CREATE TABLE IF NOT EXISTS log_ejercicios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    asignacion_id INT NOT NULL,
    ejercicio_maestro_id INT NOT NULL,
    orden INT NOT NULL,
    series_planificadas VARCHAR(50) NOT NULL COMMENT 'Snapshot: "3", "4", etc.',
    reps_planificados VARCHAR(50) NOT NULL COMMENT 'Snapshot: "8-12", "10", "Al fallo", etc.',
    carga_planificada VARCHAR(100) NULL COMMENT 'Snapshot: "50kg", "RPE 8", etc.',
    descanso_planificado VARCHAR(100) NULL COMMENT 'Snapshot: "90s", "3min", etc.',
    notas_planificadas TEXT NULL COMMENT 'Snapshot: Notas originales del plan',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (asignacion_id) REFERENCES asignaciones_agenda(id) ON DELETE CASCADE,
    FOREIGN KEY (ejercicio_maestro_id) REFERENCES ejercicios_maestro(id) ON DELETE CASCADE
);

-- 10. Tabla de Log de Series (NUEVA - FASE J)
-- Registra el desempeño ACTUAL de cada serie completada por el asesorado
-- Desacoplado del plan original para permitir variabilidad en la ejecución
CREATE TABLE IF NOT EXISTS log_series (
    id INT AUTO_INCREMENT PRIMARY KEY,
    log_ejercicio_id INT NOT NULL,
    num_serie INT NOT NULL COMMENT 'Número de serie: 1, 2, 3, etc.',
    reps_logradas INT NOT NULL COMMENT 'Repeticiones reales completadas',
    carga_lograda DECIMAL(7,2) NULL COMMENT 'Carga real usada en kg',
    completada BOOLEAN NOT NULL DEFAULT TRUE,
    notas TEXT NULL COMMENT 'Notas del asesorado sobre la serie ("Muy pesado", "Fácil", etc.)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (log_ejercicio_id) REFERENCES log_ejercicios(id) ON DELETE CASCADE
);

-- Procedimiento para crear índices de forma idempotente
DROP PROCEDURE IF EXISTS CreateIndexIfNotExists;
DELIMITER $$
CREATE PROCEDURE CreateIndexIfNotExists(
    IN p_table_name VARCHAR(128),
    IN p_index_name VARCHAR(128),
    IN p_index_columns VARCHAR(256)
)
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.statistics
        WHERE table_schema = DATABASE()
        AND table_name = p_table_name
        AND index_name = p_index_name
    ) THEN
        SET @s = CONCAT('CREATE INDEX ', p_index_name, ' ON ', p_table_name, '(', p_index_columns, ')');
        PREPARE stmt FROM @s;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$
DELIMITER ;

-- Crear índices básicos para búsquedas rápidas
CALL CreateIndexIfNotExists('asesorados', 'idx_asesorado_nombre', 'nombre');
CALL CreateIndexIfNotExists('asesorados', 'idx_asesorados_status', 'status');
CALL CreateIndexIfNotExists('asesorados', 'idx_asesorados_plan_status', 'plan_id, status');

CALL CreateIndexIfNotExists('asignaciones_agenda', 'idx_agenda_fecha', 'fecha_asignada');
CALL CreateIndexIfNotExists('asignaciones_agenda', 'idx_asignaciones_asesorado_fecha', 'asesorado_id, fecha_asignada');
CALL CreateIndexIfNotExists('asignaciones_agenda', 'idx_asignaciones_status', 'status');
CALL CreateIndexIfNotExists('asignaciones_agenda', 'idx_asignaciones_asesorado_plantilla', 'asesorado_id, plantilla_id');
CALL CreateIndexIfNotExists('asignaciones_agenda', 'idx_asignaciones_batch_fecha', 'batch_id, fecha_asignada');

CALL CreateIndexIfNotExists('mediciones', 'idx_mediciones_asesorado_fecha', 'asesorado_id, fecha_medicion DESC');

CALL CreateIndexIfNotExists('planes', 'idx_planes_coach_id', 'coach_id');
CALL CreateIndexIfNotExists('coaches', 'idx_coaches_email', 'email');

CALL CreateIndexIfNotExists('pagos_membresias', 'idx_pagos_asesorado', 'asesorado_id');

CALL CreateIndexIfNotExists('planes_nutricionales', 'idx_planes_nutricionales_asesorado', 'asesorado_id');

CALL CreateIndexIfNotExists('rutina_batches', 'idx_rutina_batches_asesorado', 'asesorado_id, rutina_id');

-- Índices para las nuevas tablas de logs (FASE J)
CALL CreateIndexIfNotExists('log_ejercicios', 'idx_log_ejercicios_asignacion', 'asignacion_id');
CALL CreateIndexIfNotExists('log_ejercicios', 'idx_log_ejercicios_maestro', 'ejercicio_maestro_id');
CALL CreateIndexIfNotExists('log_series', 'idx_log_series_ejercicio', 'log_ejercicio_id');

-- ========================================
-- OPTIMIZACIONES FASE F: ÍNDICES ADICIONALES
-- Agregados para mejorar performance de queries frecuentes
-- ========================================

-- Índices estratégicos para búsquedas de pagos pendientes
CALL CreateIndexIfNotExists('asesorados', 'idx_asesorados_coach_id', 'coach_id');
CALL CreateIndexIfNotExists('asesorados', 'idx_asesorados_fecha_vencimiento', 'fecha_vencimiento');
CALL CreateIndexIfNotExists('asesorados', 'idx_asesorados_coach_vencimiento', 'coach_id, fecha_vencimiento');

-- Índices en tabla bitácora (si existe tabla de bitácora para notas)
-- (Se crea dinámicamente si es necesaria)

-- Índices en tabla de métricas activas (para buscar por asesorado y coach)
CALL CreateIndexIfNotExists('mediciones', 'idx_mediciones_asesorado', 'asesorado_id');
CALL CreateIndexIfNotExists('mediciones', 'idx_mediciones_coach', 'asesorado_id');

-- ========================================
-- NUEVA TABLA P2: SELECCIÓN DE MÉTRICAS POR ASESORADO
-- Permite al coach seleccionar qué métricas desea rastrear para cada asesorado
-- ========================================

CREATE TABLE IF NOT EXISTS asesorado_metricas_activas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    asesorado_id INT NOT NULL UNIQUE,
    peso_activo BOOLEAN DEFAULT TRUE,
    imc_activo BOOLEAN DEFAULT TRUE,
    porcentaje_grasa_activo BOOLEAN DEFAULT TRUE,
    masa_muscular_activo BOOLEAN DEFAULT TRUE,
    agua_corporal_activo BOOLEAN DEFAULT TRUE,
    pecho_cm_activo BOOLEAN DEFAULT FALSE,
    cintura_cm_activo BOOLEAN DEFAULT FALSE,
    cadera_cm_activo BOOLEAN DEFAULT FALSE,
    brazo_izq_cm_activo BOOLEAN DEFAULT FALSE,
    brazo_der_cm_activo BOOLEAN DEFAULT FALSE,
    pierna_izq_cm_activo BOOLEAN DEFAULT FALSE,
    pierna_der_cm_activo BOOLEAN DEFAULT FALSE,
    pantorrilla_izq_cm_activo BOOLEAN DEFAULT FALSE,
    pantorrilla_der_cm_activo BOOLEAN DEFAULT FALSE,
    frecuencia_cardiaca_activo BOOLEAN DEFAULT FALSE,
    record_resistencia_activo BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (asesorado_id) REFERENCES asesorados(id) ON DELETE CASCADE,
    INDEX idx_asesorado_metricas_activas_asesorado_id (asesorado_id)
);

-- ========================================
-- VISTAS PRECALCULADAS FASE F
-- Para acceso rápido a datos consolidados sin queries complejas
-- ========================================

-- Vista 1: Resumen de Pagos Pendientes por Coach
DROP VIEW IF EXISTS vw_pagos_pendientes_resumen;
CREATE VIEW vw_pagos_pendientes_resumen AS
SELECT 
    a.coach_id,
    COALESCE(a.coach_id, 0) AS coach_id_safe,
    COUNT(DISTINCT a.id) as total_asesorados_con_pagos,
    SUM(COALESCE(p.costo, 0.0)) as monto_total_pendiente,
    COUNT(CASE WHEN a.fecha_vencimiento < CURDATE() THEN 1 END) as pagos_atrasados,
    COUNT(CASE WHEN a.fecha_vencimiento BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY) THEN 1 END) as pagos_proximos,
    MAX(a.fecha_vencimiento) as proximo_vencimiento
FROM asesorados a
LEFT JOIN planes p ON a.plan_id = p.id
WHERE a.plan_id IS NOT NULL
  AND (a.fecha_vencimiento IS NULL OR a.fecha_vencimiento <= DATE_ADD(CURDATE(), INTERVAL 30 DAY))
GROUP BY a.coach_id;

-- Vista 2: Mediciones Consolidadas por Asesorado
DROP VIEW IF EXISTS vw_mediciones_resumen;
CREATE VIEW vw_mediciones_resumen AS
SELECT 
    asesorado_id,
    COUNT(*) as total_mediciones,
    MAX(fecha_medicion) as ultima_medicion,
    MIN(fecha_medicion) as primera_medicion,
    MAX(peso) as peso_actual,
    MIN(peso) as peso_minimo,
    ROUND(AVG(peso), 2) as peso_promedio,
    MAX(porcentaje_grasa) as grasa_actual,
    MIN(imc) as imc_minimo,
    MAX(imc) as imc_maximo
FROM mediciones
GROUP BY asesorado_id;

-- ========================================
-- PROCEDURE PARA ANÁLISIS DE PERFORMANCE (Opcional)
-- ========================================

DROP PROCEDURE IF EXISTS AnalizarPerformance;
DELIMITER $$
CREATE PROCEDURE AnalizarPerformance()
BEGIN
    -- Mostrar estadísticas de uso de índices
    SELECT 
        OBJECT_SCHEMA,
        OBJECT_NAME,
        COUNT_READ,
        COUNT_WRITE,
        COUNT_DELETE,
        COUNT_INSERT,
        COUNT_UPDATE
    FROM performance_schema.table_io_waits_summary_by_table
    WHERE OBJECT_SCHEMA = 'coachhub_db'
    ORDER BY COUNT_READ DESC;
END$$
DELIMITER ;

-- Eliminar el procedimiento después de usarlo
DROP PROCEDURE IF EXISTS CreateIndexIfNotExists;

-- ========================================
-- VERIFICACIÓN DE SCHEMA
-- ========================================

-- Listar todas las tablas creadas
SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'coachhub_db' ORDER BY TABLE_NAME;

-- ========================================
-- SCHEMA COMPLETADO EXITOSAMENTE
-- Base de datos lista para usar con todas las características:
-- ✅ Gestión de Asesorados
-- ✅ Mediciones y Métricas (incluyendo 8 nuevos campos expandidos)
-- ✅ Planes Nutricionales
-- ✅ Pagos de Membresías
-- ✅ Gestión de Rutinas y Ejercicios
-- ✅ Agenda de Asignaciones
-- ✅ Notas de Seguimiento
-- ✅ Gestión de Coaches
-- ✅ Índices de Performance
-- ✅ FASE J: Sistema de Logs de Ejercicios (Snapshot Pattern)
--    - log_ejercicios: Captura snapshot de plan
--    - log_series: Registro de desempeño real
-- ========================================

-- ========================================
-- EJERCICIOS MAESTRO - INSERCIONES
-- Generado automáticamente desde exercises_es.json
-- NOTA: Sesión 8 - Cambio de TRUNCATE a DELETE para evitar Error 1701
-- ========================================

-- Limpiar tabla existente (opcional)
-- Cambio: TRUNCATE → DELETE (respeta Foreign Keys)
-- Nota: WHERE id>0 usa PRIMARY KEY para Safe Update Mode (Error 1175)
DELETE FROM ejercicios_maestro WHERE id > 0;

-- Insertar ejercicios
INSERT IGNORE INTO ejercicios_maestro (nombre, musculo_principal, equipamiento, image_url, fuente) VALUES
('Abdominal 3/4', 'abdominales', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/3_4_Sit-Up/0.jpg', 'free-exercise-db'),
('90/90 Isquiotibiales', 'isquiotibiales', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/90_90_Hamstring/0.jpg', 'free-exercise-db'),
('Máquina de Abdominales', 'abdominales', 'máquina', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Ab_Crunch_Machine/0.jpg', 'free-exercise-db'),
('Rodillo Abdominal', 'abdominales', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Ab_Roller/0.jpg', 'free-exercise-db'),
('Aductores', 'aductores', 'rodillo de espuma', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Adductor/0.jpg', 'free-exercise-db'),
('Aductor/ingle', 'aductores', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Adductor_Groin/0.jpg', 'free-exercise-db'),
('Molinillo avanzado con pesa rusa', 'abdominales', 'pesas rusas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Advanced_Kettlebell_Windmill/0.jpg', 'free-exercise-db'),
('Bicicleta de Aire', 'abdominales', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Air_Bike/0.jpg', 'free-exercise-db'),
('Estiramiento de cuádriceps en posición de cuadrupedia.', 'cuádriceps', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/All_Fours_Quad_Stretch/0.jpg', 'free-exercise-db'),
('Curl de martillo alternado', 'bíceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Alternate_Hammer_Curl/0.jpg', 'free-exercise-db'),
('Toques de talón alternados', 'abdominales', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Alternate_Heel_Touchers/0.jpg', 'free-exercise-db'),
('Curl con mancuernas en banco inclinado alternado.', 'bíceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Alternate_Incline_Dumbbell_Curl/0.jpg', 'free-exercise-db'),
('Salto diagonal con piernas alternadas', 'cuádriceps', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Alternate_Leg_Diagonal_Bound/0.jpg', 'free-exercise-db'),
('Press de hombros con cable alternando.', 'hombros', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Alternating_Cable_Shoulder_Press/0.jpg', 'free-exercise-db'),
('Elevación alterna de deltoides', 'hombros', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Alternating_Deltoid_Raise/0.jpg', 'free-exercise-db'),
('Prensa de piso alternada', 'pecho', 'pesas rusas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Alternating_Floor_Press/0.jpg', 'free-exercise-db'),
('Hang Clean Alternante', 'isquiotibiales', 'pesas rusas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Alternating_Hang_Clean/0.jpg', 'free-exercise-db'),
('Prensa alterna de pesas rusas', 'hombros', 'pesas rusas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Alternating_Kettlebell_Press/0.jpg', 'free-exercise-db'),
('Fila alterna con pesa rusa', 'espalda media', 'pesas rusas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Alternating_Kettlebell_Row/0.jpg', 'free-exercise-db'),
('Fila Renegada Alternada', 'espalda media', 'pesas rusas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Alternating_Renegade_Row/0.jpg', 'free-exercise-db'),
('Círculos de tobillo', 'Las pantorrillas', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Ankle_Circles/0.jpg', 'free-exercise-db'),
('Tobillo en la rodilla.', 'glúteos', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Ankle_On_The_Knee/0.jpg', 'free-exercise-db'),
('Tibial anterior-SMR.', 'Las pantorrillas', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Anterior_Tibialis-SMR/0.jpg', 'free-exercise-db'),
('Prensa antigravedad', 'hombros', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Anti-Gravity_Press/0.jpg', 'free-exercise-db'),
('Círculos con los brazos', 'hombros', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Arm_Circles/0.jpg', 'free-exercise-db'),
('Press de mancuerna Arnold', 'hombros', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Arnold_Dumbbell_Press/0.jpg', 'free-exercise-db'),
('Alrededor del mundo.', 'pecho', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Around_The_Worlds/0.jpg', 'free-exercise-db'),
('Entrenador de piedra Atlas', 'espalda baja', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Atlas_Stone_Trainer/0.jpg', 'free-exercise-db'),
('Piedras de Atlas', 'espalda baja', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Atlas_Stones/0.jpg', 'free-exercise-db'),
('Peso Muerto con Eje', 'espalda baja', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Axle_Deadlift/0.jpg', 'free-exercise-db'),
('Vuelo de espalda - Con bandas', 'hombros', 'bandas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Back_Flyes_-_With_Bands/0.jpg', 'free-exercise-db'),
('Arrastre hacia atrás', 'cuádriceps', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Backward_Drag/0.jpg', 'free-exercise-db'),
('Lanzamiento de balón medicinal hacia atrás', 'hombros', 'balón medicinal', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Backward_Medicine_Ball_Throw/0.jpg', 'free-exercise-db'),
('Tabla de equilibrio', 'Las pantorrillas', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Balance_Board/0.jpg', 'free-exercise-db'),
('Flexión de piernas con pelota', 'isquiotibiales', 'pelota de ejercicio', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Ball_Leg_Curl/0.jpg', 'free-exercise-db'),
('Pull-Up asistido por banda', 'Los lats', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Band_Assisted_Pull-Up/0.jpg', 'free-exercise-db'),
('Buenos días.', 'isquiotibiales', 'bandas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Band_Good_Morning/0.jpg', 'free-exercise-db'),
('Banda Good Morning (Pull Through)', 'isquiotibiales', 'bandas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Band_Good_Morning_Pull_Through/0.jpg', 'free-exercise-db'),
('Aducciones de cadera con banda', 'aductores', 'bandas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Band_Hip_Adductions/0.jpg', 'free-exercise-db'),
('Separación de banda', 'hombros', 'bandas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Band_Pull_Apart/0.jpg', 'free-exercise-db'),
('Banda Cráneo Triturador', 'tríceps', 'bandas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Band_Skull_Crusher/0.jpg', 'free-exercise-db'),
('Desplazamiento con barra para abdominales', 'abdominales', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Ab_Rollout/0.jpg', 'free-exercise-db'),
('Rueda de abdominal con barra - de rodillas', 'abdominales', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Ab_Rollout_-_On_Knees/0.jpg', 'free-exercise-db'),
('Press de banca con barra - agarre medio', 'pecho', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Bench_Press_-_Medium_Grip/0.jpg', 'free-exercise-db'),
('Curl de barra.', 'bíceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Curl/0.jpg', 'free-exercise-db'),
('Curl de barra acostado contra una inclinación', 'bíceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Curls_Lying_Against_An_Incline/0.jpg', 'free-exercise-db'),
('Levantamiento de pesas con barra', 'espalda baja', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Deadlift/0.jpg', 'free-exercise-db'),
('Sentadilla completa con barra', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Full_Squat/0.jpg', 'free-exercise-db'),
('Puente de Glúteos con Barra', 'glúteos', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Glute_Bridge/0.jpg', 'free-exercise-db'),
('Prensa de banca con barra tipo guillotina', 'pecho', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Guillotine_Bench_Press/0.jpg', 'free-exercise-db'),
('Sentadilla con barra hack', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Hack_Squat/0.jpg', 'free-exercise-db'),
('Empuje de cadera con barra', 'glúteos', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Hip_Thrust/0.jpg', 'free-exercise-db'),
('Press de banca inclinado con barra - agarre medio', 'pecho', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Incline_Bench_Press_-_Medium_Grip/0.jpg', 'free-exercise-db'),
('Elevación lateral del hombro con barra en banco inclinado', 'hombros', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Incline_Shoulder_Raise/0.jpg', 'free-exercise-db'),
('Desplante con barra', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Lunge/0.jpg', 'free-exercise-db'),
('Remo de deltoides posterior con barra', 'hombros', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Rear_Delt_Row/0.jpg', 'free-exercise-db'),
('Rodillo de barra desde el banco', 'abdominales', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Rollout_from_Bench/0.jpg', 'free-exercise-db'),
('Elevación de talones sentado con barra.', 'Las pantorrillas', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Seated_Calf_Raise/0.jpg', 'free-exercise-db'),
('Press militar con barra', 'hombros', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Shoulder_Press/0.jpg', 'free-exercise-db'),
('Elevación de hombros con barra.', 'trampas', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Shrug/0.jpg', 'free-exercise-db'),
('Elevación de hombros con barra detrás de la espalda.', 'trampas', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Shrug_Behind_The_Back/0.jpg', 'free-exercise-db'),
('Flexión lateral con barra', 'abdominales', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Side_Bend/0.jpg', 'free-exercise-db'),
('Sentadilla lateral con barra', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Side_Split_Squat/0.jpg', 'free-exercise-db'),
('Sentadilla con barra', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Squat/0.jpg', 'free-exercise-db'),
('Sentadilla con barra en banco.', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Squat_To_A_Bench/0.jpg', 'free-exercise-db'),
('Elevación de pesas con barra', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Step_Ups/0.jpg', 'free-exercise-db'),
('Peso muerto en zancada', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Walking_Lunge/0.jpg', 'free-exercise-db'),
('Cuerdas de batalla', 'hombros', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Battling_Ropes/0.jpg', 'free-exercise-db'),
('Arrastres de trineo a gatas', 'cuádriceps', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bear_Crawl_Sled_Drags/0.jpg', 'free-exercise-db'),
('Estiramiento de pecho con las manos detrás de la cabeza.', 'pecho', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Behind_Head_Chest_Stretch/0.jpg', 'free-exercise-db'),
('Fondos en banco.', 'tríceps', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bench_Dips/0.jpg', 'free-exercise-db'),
('Salto de banco', 'cuádriceps', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bench_Jump/0.jpg', 'free-exercise-db'),
('Press de banca - Levantamiento de potencia', 'tríceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bench_Press_-_Powerlifting/0.jpg', 'free-exercise-db'),
('Press de banca - con bandas', 'pecho', 'bandas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bench_Press_-_With_Bands/0.jpg', 'free-exercise-db'),
('Press de banca con cadenas', 'tríceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bench_Press_with_Chains/0.jpg', 'free-exercise-db'),
('Sprint en el banco', 'cuádriceps', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bench_Sprint/0.jpg', 'free-exercise-db'),
('Pullover con barra y brazos doblados', 'Los lats', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bent-Arm_Barbell_Pullover/0.jpg', 'free-exercise-db'),
('Polea con Mancuerna con los Brazos Flexionados', 'pecho', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bent-Arm_Dumbbell_Pullover/0.jpg', 'free-exercise-db'),
('Elevación de cadera con rodilla flexionada', 'abdominales', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bent-Knee_Hip_Raise/0.jpg', 'free-exercise-db'),
('Remo con barra inclinado', 'espalda media', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bent_Over_Barbell_Row/0.jpg', 'free-exercise-db'),
('Elevación lateral de deltoides trasero con mancuernas inclinado con la cabeza apoyada en el banco', 'hombros', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bent_Over_Dumbbell_Rear_Delt_Raise_With_Head_On_Bench/0.jpg', 'free-exercise-db'),
('Laterales de hombro con polea baja inclinada', 'hombros', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bent_Over_Low-Pulley_Side_Lateral/0.jpg', 'free-exercise-db'),
('Remo con barra larga a un brazo inclinado', 'espalda media', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bent_Over_One-Arm_Long_Bar_Row/0.jpg', 'free-exercise-db'),
('Remo con barra larga inclinado de dos brazos', 'espalda media', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bent_Over_Two-Arm_Long_Bar_Row/0.jpg', 'free-exercise-db'),
('Remo inclinado con dos mancuernas', 'espalda media', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bent_Over_Two-Dumbbell_Row/0.jpg', 'free-exercise-db'),
('Remo inclinado con dos mancuernas y palmas hacia adentro.', 'espalda media', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bent_Over_Two-Dumbbell_Row_With_Palms_In/0.jpg', 'free-exercise-db'),
('Prensa inclinada', 'abdominales', 'pesas rusas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bent_Press/0.jpg', 'free-exercise-db'),
('Andar en bicicleta', 'cuádriceps', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bicycling/0.jpg', 'free-exercise-db'),
('Ciclismo, Estacionario', 'cuádriceps', 'máquina', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bicycling_Stationary/0.jpg', 'free-exercise-db'),
('Prensa de Tabla', 'tríceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Board_Press/0.jpg', 'free-exercise-db'),
('Cuerpo hacia arriba', 'tríceps', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Body-Up/0.jpg', 'free-exercise-db'),
('Prensa de tríceps en cuerpo', 'tríceps', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Body_Tricep_Press/0.jpg', 'free-exercise-db'),
('Flyes con peso corporal', 'pecho', 'barra de curl con forma de "e-z"', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bodyweight_Flyes/0.jpg', 'free-exercise-db'),
('Fila a mitad del cuerpo con peso corporal', 'espalda media', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bodyweight_Mid_Row/0.jpg', 'free-exercise-db'),
('Sentadilla sin peso.', 'cuádriceps', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bodyweight_Squat/0.jpg', 'free-exercise-db'),
('Zancada con peso corporal', 'cuádriceps', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bodyweight_Walking_Lunge/0.jpg', 'free-exercise-db'),
('Crunch con cable en balón Bosu con inclinaciones laterales.', 'abdominales', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bosu_Ball_Cable_Crunch_With_Side_Bends/0.jpg', 'free-exercise-db'),
('Limpieza desde la posición de colgar de abajo hacia arriba.', 'antebrazos', 'pesas rusas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bottoms-Up_Clean_From_The_Hang_Position/0.jpg', 'free-exercise-db'),
('¡Salud!', 'abdominales', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bottoms_Up/0.jpg', 'free-exercise-db'),
('Salto a la caja (Respuesta múltiple)', 'isquiotibiales', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Box_Jump_Multiple_Response/0.jpg', 'free-exercise-db'),
('Omitir Caja', 'isquiotibiales', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Box_Skip/0.jpg', 'free-exercise-db'),
('Sentadilla en caja', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Box_Squat/0.jpg', 'free-exercise-db'),
('Sentadillas en caja con bandas', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Box_Squat_with_Bands/0.jpg', 'free-exercise-db'),
('Sentadillas en caja con cadenas.', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Box_Squat_with_Chains/0.jpg', 'free-exercise-db'),
('Brachialis-SMR', 'bíceps', 'rodillo de espuma', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Brachialis-SMR/0.jpg', 'free-exercise-db'),
('Bradford/Rocky Prensas', 'hombros', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bradford_Rocky_Presses/0.jpg', 'free-exercise-db'),
('Flexiones de glúteos', 'abdominales', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Butt-Ups/0.jpg', 'free-exercise-db'),
('Elevación de glúteos (puente)', 'glúteos', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Butt_Lift_Bridge/0.jpg', 'free-exercise-db'),
('Mariposa', 'pecho', 'máquina', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Butterfly/0.jpg', 'free-exercise-db'),
('Prensa de pecho con cable', 'pecho', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cable_Chest_Press/0.jpg', 'free-exercise-db'),
('Cruz de cables', 'pecho', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cable_Crossover/0.jpg', 'free-exercise-db'),
('Crunch con cable', 'abdominales', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cable_Crunch/0.jpg', 'free-exercise-db'),
('Peso muerto con cable', 'cuádriceps', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cable_Deadlifts/0.jpg', 'free-exercise-db'),
('Curls de martillo con cable - Accesorio de cuerda', 'bíceps', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cable_Hammer_Curls_-_Rope_Attachment/0.jpg', 'free-exercise-db'),
('Aducción de cadera con cable', 'cuádriceps', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cable_Hip_Adduction/0.jpg', 'free-exercise-db'),
('Extensión de tríceps aérea con polea', 'Los lats', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cable_Incline_Pushdown/0.jpg', 'free-exercise-db'),
('Extensión de tríceps en polea inclinada', 'tríceps', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cable_Incline_Triceps_Extension/0.jpg', 'free-exercise-db'),
('Rotación interna del cable', 'hombros', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cable_Internal_Rotation/0.jpg', 'free-exercise-db'),
('Cruz de hierro con cable', 'pecho', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cable_Iron_Cross/0.jpg', 'free-exercise-db'),
('Cable Judo Flip - Salto de judo con cable', 'abdominales', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cable_Judo_Flip/0.jpg', 'free-exercise-db'),
('Extensión de tríceps acostado con cable', 'tríceps', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cable_Lying_Triceps_Extension/0.jpg', 'free-exercise-db'),
('Extensión de tríceps con un solo brazo', 'tríceps', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cable_One_Arm_Tricep_Extension/0.jpg', 'free-exercise-db'),
('Curl de predicador con cable.', 'bíceps', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cable_Preacher_Curl/0.jpg', 'free-exercise-db'),
('Vuelo de Deltoides Posterior con Cable', 'hombros', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cable_Rear_Delt_Fly/0.jpg', 'free-exercise-db'),
('Elevación de piernas en polea inversa', 'abdominales', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cable_Reverse_Crunch/0.jpg', 'free-exercise-db'),
('Extensión de tríceps en polea por encima de la cabeza', 'tríceps', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cable_Rope_Overhead_Triceps_Extension/0.jpg', 'free-exercise-db'),
('Filas de Deltoides Posterior con Cable de Cuerda', 'hombros', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cable_Rope_Rear-Delt_Rows/0.jpg', 'free-exercise-db'),
('Giros rusos con cuerda', 'abdominales', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cable_Russian_Twists/0.jpg', 'free-exercise-db'),
('Abdominales en polea sentado', 'abdominales', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cable_Seated_Crunch/0.jpg', 'free-exercise-db'),
('Elevación lateral sentado con cable', 'hombros', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cable_Seated_Lateral_Raise/0.jpg', 'free-exercise-db'),
('Prensa de hombros con cable', 'hombros', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cable_Shoulder_Press/0.jpg', 'free-exercise-db'),
('Encogimiento de hombros con cable', 'trampas', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cable_Shrugs/0.jpg', 'free-exercise-db'),
('Curl de muñeca con cable', 'antebrazos', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cable_Wrist_Curl/0.jpg', 'free-exercise-db'),
('Elevación de hombros en máquina para pantorrillas.', 'trampas', 'máquina', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Calf-Machine_Shoulder_Shrug/0.jpg', 'free-exercise-db'),
('Prensa de pantorrillas.', 'Las pantorrillas', 'máquina', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Calf_Press/0.jpg', 'free-exercise-db'),
('Prensa de pantorrilla en la máquina de prensa de piernas.', 'Las pantorrillas', 'máquina', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Calf_Press_On_The_Leg_Press_Machine/0.jpg', 'free-exercise-db'),
('Elevación de talones con mancuerna', 'Las pantorrillas', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Calf_Raise_On_A_Dumbbell/0.jpg', 'free-exercise-db'),
('Elevación de talones - Con bandas', 'Las pantorrillas', 'bandas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Calf_Raises_-_With_Bands/0.jpg', 'free-exercise-db'),
('Estiramiento de pantorrilla con codos contra la pared.', 'Las pantorrillas', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Calf_Stretch_Elbows_Against_Wall/0.jpg', 'free-exercise-db'),
('Estiramiento de pantorrillas con las manos contra la pared.', 'Las pantorrillas', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Calf_Stretch_Hands_Against_Wall/0.jpg', 'free-exercise-db'),
('Terneros-SMR', 'Las pantorrillas', 'rodillo de espuma', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Calves-SMR/0.jpg', 'free-exercise-db'),
('Levantamiento de auto', 'cuádriceps', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Car_Deadlift/0.jpg', 'free-exercise-db'),
('Conductores de vehículos', 'hombros', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Car_Drivers/0.jpg', 'free-exercise-db'),
('Paso rápido carioca', 'aductores', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Carioca_Quick_Step/0.jpg', 'free-exercise-db'),
('Estiramiento de gato', 'espalda baja', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cat_Stretch/0.jpg', 'free-exercise-db'),
('Atrapa y lanzamiento por encima de la cabeza', 'Los lats', 'balón medicinal', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Catch_and_Overhead_Throw/0.jpg', 'free-exercise-db'),
('Extensión de asa de cadena', 'tríceps', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Chain_Handle_Extension/0.jpg', 'free-exercise-db'),
('Prensa de Cadena', 'pecho', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Chain_Press/0.jpg', 'free-exercise-db'),
('Estiramiento de la Pierna Extendida sobre la Silla', 'isquiotibiales', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Chair_Leg_Extended_Stretch/0.jpg', 'free-exercise-db'),
('Estiramiento de la parte baja de la espalda en silla', 'Los lats', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Chair_Lower_Back_Stretch/0.jpg', 'free-exercise-db'),
('Sentadilla en silla', 'cuádriceps', 'máquina', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Chair_Squat/0.jpg', 'free-exercise-db'),
('Estiramiento de la parte superior del cuerpo en silla', 'hombros', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Chair_Upper_Body_Stretch/0.jpg', 'free-exercise-db'),
('Estiramiento de pecho y parte frontal del hombro.', 'pecho', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Chest_And_Front_Of_Shoulder_Stretch/0.jpg', 'free-exercise-db'),
('Empuje de pecho desde posición de tres puntos.', 'pecho', 'balón medicinal', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Chest_Push_from_3_point_stance/0.jpg', 'free-exercise-db'),
('Empuje de pecho (respuesta múltiple)', 'pecho', 'balón medicinal', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Chest_Push_multiple_response/0.jpg', 'free-exercise-db'),
('Empuje de pecho (respuesta única)', 'pecho', 'balón medicinal', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Chest_Push_single_response/0.jpg', 'free-exercise-db'),
('Empuje de pecho con liberación de carrera', 'pecho', 'balón medicinal', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Chest_Push_with_Run_Release/0.jpg', 'free-exercise-db'),
('Estiramiento de pecho en la pelota de estabilidad', 'pecho', 'pelota de ejercicio', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Chest_Stretch_on_Stability_Ball/0.jpg', 'free-exercise-db'),
('Postura del niño', 'espalda baja', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Childs_Pose/0.jpg', 'free-exercise-db'),
('Dominada', 'Los lats', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Chin-Up/0.jpg', 'free-exercise-db'),
('Estiramiento de mentón al pecho.', 'cuello', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Chin_To_Chest_Stretch/0.jpg', 'free-exercise-db'),
('Campana de circo', 'hombros', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Circus_Bell/0.jpg', 'free-exercise-db'),
('Limpiar', 'isquiotibiales', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Clean/0.jpg', 'free-exercise-db'),
('Peso muerto limpio', 'isquiotibiales', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Clean_Deadlift/0.jpg', 'free-exercise-db'),
('Tirón limpio', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Clean_Pull/0.jpg', 'free-exercise-db'),
('Encogimiento de Hombros Limpio', 'trampas', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Clean_Shrug/0.jpg', 'free-exercise-db'),
('Arrancada y envión', 'hombros', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Clean_and_Jerk/0.jpg', 'free-exercise-db'),
('Limpiar y presionar', 'hombros', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Clean_and_Press/0.jpg', 'free-exercise-db'),
('Limpiar de bloques', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Clean_from_Blocks/0.jpg', 'free-exercise-db'),
('Flexiones de reloj', 'pecho', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Clock_Push-Up/0.jpg', 'free-exercise-db'),
('Press de banca con barra de agarre cerrado', 'tríceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Close-Grip_Barbell_Bench_Press/0.jpg', 'free-exercise-db'),
('Press de mancuernas con agarre cerrado', 'tríceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Close-Grip_Dumbbell_Press/0.jpg', 'free-exercise-db'),
('Curl de barra EZ de agarre cerrado con banda.', 'bíceps', 'barra de curl con forma de "e-z"', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Close-Grip_EZ-Bar_Curl_with_Band/0.jpg', 'free-exercise-db'),
('Press de barra EZ con agarre cerrado', 'tríceps', 'barra de curl con forma de "e-z"', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Close-Grip_EZ-Bar_Press/0.jpg', 'free-exercise-db'),
('Curl con barra EZ de agarre cerrado', 'bíceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Close-Grip_EZ_Bar_Curl/0.jpg', 'free-exercise-db'),
('Flexiones de Polea Frontal con agarre cerrado.', 'Los lats', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Close-Grip_Front_Lat_Pulldown/0.jpg', 'free-exercise-db'),
('Flexiones de agarre cerrado sobre una mancuerna', 'tríceps', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Close-Grip_Push-Up_off_of_a_Dumbbell/0.jpg', 'free-exercise-db'),
('Curl de barra con agarre cerrado de pie', 'bíceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Close-Grip_Standing_Barbell_Curl/0.jpg', 'free-exercise-db'),
('Capullos', 'abdominales', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cocoons/0.jpg', 'free-exercise-db'),
('La rueda de Conan', 'cuádriceps', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Conans_Wheel/0.jpg', 'free-exercise-db'),
('Curl de concentración', 'bíceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Concentration_Curls/0.jpg', 'free-exercise-db'),
('Crunch cruzado de cuerpo', 'abdominales', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cross-Body_Crunch/0.jpg', 'free-exercise-db'),
('Curl de martillo cruzado', 'bíceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cross_Body_Hammer_Curl/0.jpg', 'free-exercise-db'),
('Cruce - Con bandas', 'pecho', 'bandas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cross_Over_-_With_Bands/0.jpg', 'free-exercise-db'),
('Zancada inversa con cruce', 'espalda baja', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Crossover_Reverse_Lunge/0.jpg', 'free-exercise-db'),
('Crucifijo', 'hombros', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Crucifix/0.jpg', 'free-exercise-db'),
('Crunch - Manos sobre la cabeza.', 'abdominales', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Crunch_-_Hands_Overhead/0.jpg', 'free-exercise-db'),
('Elevación de piernas en balón de ejercicio.', 'abdominales', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Crunch_-_Legs_On_Exercise_Ball/0.jpg', 'free-exercise-db'),
('Abdominales', 'abdominales', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Crunches/0.jpg', 'free-exercise-db'),
('Prensa cubana', 'hombros', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cuban_Press/0.jpg', 'free-exercise-db'),
('Estiramiento de bailarín', 'espalda baja', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dancers_Stretch/0.jpg', 'free-exercise-db'),
('Bicho muerto', 'abdominales', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dead_Bug/0.jpg', 'free-exercise-db'),
('Levantamiento de peso muerto con bandas', 'espalda baja', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Deadlift_with_Bands/0.jpg', 'free-exercise-db'),
('Levantamiento de pesas con cadenas.', 'espalda baja', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Deadlift_with_Chains/0.jpg', 'free-exercise-db'),
('Flexiones declinadas con barra', 'pecho', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Decline_Barbell_Bench_Press/0.jpg', 'free-exercise-db'),
('Declinar Press de banca con agarre cerrado a extensiones de tríceps en la frente', 'tríceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Decline_Close-Grip_Bench_To_Skull_Crusher/0.jpg', 'free-exercise-db'),
('Abdominales oblicuos', 'abdominales', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Decline_Crunch/0.jpg', 'free-exercise-db'),
('Declinar Press de Banca con Mancuernas', 'pecho', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Decline_Dumbbell_Bench_Press/0.jpg', 'free-exercise-db'),
('Declina Flexiones con Mancuernas', 'pecho', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Decline_Dumbbell_Flyes/0.jpg', 'free-exercise-db'),
('Extensión de tríceps con mancuerna', 'tríceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Decline_Dumbbell_Triceps_Extension/0.jpg', 'free-exercise-db'),
('Extensión de tríceps con barra EZ', 'tríceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Decline_EZ_Bar_Triceps_Extension/0.jpg', 'free-exercise-db'),
('Declina el Oblicuo Crunch.', 'abdominales', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Decline_Oblique_Crunch/0.jpg', 'free-exercise-db'),
('Flexión declinada', 'pecho', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Decline_Push-Up/0.jpg', 'free-exercise-db'),
('Declinar Elevación de Piernas en Banca Inclinada.', 'abdominales', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Decline_Reverse_Crunch/0.jpg', 'free-exercise-db'),
('Rechazar la prensa de Smith', 'pecho', 'máquina', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Decline_Smith_Press/0.jpg', 'free-exercise-db'),
('Desplazamiento de déficit', 'espalda baja', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Deficit_Deadlift/0.jpg', 'free-exercise-db'),
('Salto de profundidad.', 'cuádriceps', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Depth_Jump_Leap/0.jpg', 'free-exercise-db'),
('Máquina de inmersión', 'tríceps', 'máquina', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dip_Machine/0.jpg', 'free-exercise-db'),
('Flexiones - Versión de pecho', 'pecho', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dips_-_Chest_Version/0.jpg', 'free-exercise-db'),
('Flexiones - Versión de tríceps', 'tríceps', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dips_-_Triceps_Version/0.jpg', 'free-exercise-db'),
('Elevaciones de talones en burro', 'Las pantorrillas', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Donkey_Calf_Raises/0.jpg', 'free-exercise-db'),
('Cleans colgantes alternos con dos pesas kettlebell.', 'isquiotibiales', 'pesas rusas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Double_Kettlebell_Alternating_Hang_Clean/0.jpg', 'free-exercise-db'),
('Arrancada Doble con Pesas Rusas', 'hombros', 'pesas rusas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Double_Kettlebell_Jerk/0.jpg', 'free-exercise-db'),
('Press de empuje con dos pesas kettlebell', 'hombros', 'pesas rusas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Double_Kettlebell_Push_Press/0.jpg', 'free-exercise-db'),
('Arranque con dos pesas rusas', 'hombros', 'pesas rusas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Double_Kettlebell_Snatch/0.jpg', 'free-exercise-db'),
('Molinillo de Doble Pesas Kettlebell', 'abdominales', 'pesas rusas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Double_Kettlebell_Windmill/0.jpg', 'free-exercise-db'),
('Patada doble en las nalgas.', 'cuádriceps', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Double_Leg_Butt_Kick/0.jpg', 'free-exercise-db'),
('Equilibrio hacia abajo', 'glúteos', 'pelota de ejercicio', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Downward_Facing_Balance/0.jpg', 'free-exercise-db'),
('Curl de arrastre', 'bíceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Drag_Curl/0.jpg', 'free-exercise-db'),
('Empuje hacia abajo', 'pecho', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Drop_Push/0.jpg', 'free-exercise-db'),
('Curl de bíceps alterno con mancuernas', 'bíceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Alternate_Bicep_Curl/0.jpg', 'free-exercise-db'),
('Press de banca con mancuernas', 'pecho', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Bench_Press/0.jpg', 'free-exercise-db'),
('Press de banca con mancuernas con agarre neutro', 'pecho', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Bench_Press_with_Neutral_Grip/0.jpg', 'free-exercise-db'),
('Flexión de bíceps con mancuerna', 'bíceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Bicep_Curl/0.jpg', 'free-exercise-db'),
('Limpieza con mancuernas', 'isquiotibiales', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Clean/0.jpg', 'free-exercise-db'),
('Prensa de mancuernas en el suelo', 'tríceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Floor_Press/0.jpg', 'free-exercise-db'),
('Pájaros con mancuernas', 'pecho', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Flyes/0.jpg', 'free-exercise-db'),
('Fila inclinada con mancuernas', 'espalda media', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Incline_Row/0.jpg', 'free-exercise-db'),
('Elevación frontal de hombros con mancuernas', 'hombros', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Incline_Shoulder_Raise/0.jpg', 'free-exercise-db'),
('Sentadillas con Mancuernas', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Lunges/0.jpg', 'free-exercise-db'),
('Elevación lateral posterior de un brazo acostado con mancuerna', 'hombros', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Lying_One-Arm_Rear_Lateral_Raise/0.jpg', 'free-exercise-db'),
('Pronación con mancuernas acostado', 'antebrazos', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Lying_Pronation/0.jpg', 'free-exercise-db'),
('Elevación lateral trasera con mancuernas acostado', 'hombros', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Lying_Rear_Lateral_Raise/0.jpg', 'free-exercise-db'),
('Supinación acostada con mancuerna', 'antebrazos', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Lying_Supination/0.jpg', 'free-exercise-db'),
('Press de hombro con mancuerna de un solo brazo', 'hombros', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_One-Arm_Shoulder_Press/0.jpg', 'free-exercise-db'),
('Extensiones de tríceps con mancuerna de un solo brazo', 'tríceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_One-Arm_Triceps_Extension/0.jpg', 'free-exercise-db'),
('Elevación lateral con mancuerna de un brazo', 'hombros', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_One-Arm_Upright_Row/0.jpg', 'free-exercise-db'),
('Curl inclinado con mancuernas en posición prono.', 'bíceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Prone_Incline_Curl/0.jpg', 'free-exercise-db'),
('Elevación de mancuernas', 'hombros', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Raise/0.jpg', 'free-exercise-db'),
('Sentadilla con mancuerna hacia atrás', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Rear_Lunge/0.jpg', 'free-exercise-db'),
('Elevación lateral con mancuernas', 'hombros', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Scaption/0.jpg', 'free-exercise-db'),
('Salto en caja sentado con mancuernas', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Seated_Box_Jump/0.jpg', 'free-exercise-db'),
('Elevación de talones sentado con mancuerna de una pierna', 'Las pantorrillas', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Seated_One-Leg_Calf_Raise/0.jpg', 'free-exercise-db'),
('Press de hombro con mancuernas', 'hombros', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Shoulder_Press/0.jpg', 'free-exercise-db'),
('Encogimiento de hombros con mancuernas', 'trampas', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Shrug/0.jpg', 'free-exercise-db'),
('Flexión lateral con mancuerna', 'abdominales', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Side_Bend/0.jpg', 'free-exercise-db'),
('Sentadilla con mancuernas', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Squat/0.jpg', 'free-exercise-db'),
('Sentadilla con mancuerna en un banco', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Squat_To_A_Bench/0.jpg', 'free-exercise-db'),
('Elevaciones con mancuernas', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Step_Ups/0.jpg', 'free-exercise-db'),
('Extensiones de tríceps con mancuerna - agarre pronado.', 'tríceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Tricep_Extension_-Pronated_Grip/0.jpg', 'free-exercise-db'),
('Estiramiento dinámico de espalda', 'Los lats', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dynamic_Back_Stretch/0.jpg', 'free-exercise-db'),
('Estiramiento dinámico de pecho', 'pecho', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dynamic_Chest_Stretch/0.jpg', 'free-exercise-db'),
('Estiramiento dinámico de espalda', 'Los lats', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dynamic_Back_Stretch/0.jpg', 'free-exercise-db'),
('Estiramiento dinámico de pecho', 'pecho', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dynamic_Chest_Stretch/0.jpg', 'free-exercise-db'),
('Curl con barra ZEZ', 'bíceps', 'barra de curl con forma de "e-z"', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/EZ-Bar_Curl/0.jpg', 'free-exercise-db'),
('Flexiones de tríceps con barra Z', 'tríceps', 'barra de curl con forma de "e-z"', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/EZ-Bar_Skullcrusher/0.jpg', 'free-exercise-db'),
('Círculos con los codos', 'hombros', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Elbow_Circles/0.jpg', 'free-exercise-db'),
('Codo a rodilla', 'abdominales', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Elbow_to_Knee/0.jpg', 'free-exercise-db'),
('Codos hacia atrás', 'pecho', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Elbows_Back/0.jpg', 'free-exercise-db'),
('Estocada elevada', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Elevated_Back_Lunge/0.jpg', 'free-exercise-db'),
('Filas en Cable Elevadas', 'Los lats', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Elevated_Cable_Rows/0.jpg', 'free-exercise-db'),
('Entrenador elíptico', 'cuádriceps', 'máquina', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Elliptical_Trainer/0.jpg', 'free-exercise-db'),
('Crunches con pelota de ejercicio', 'abdominales', 'pelota de ejercicio', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Exercise_Ball_Crunch/0.jpg', 'free-exercise-db'),
('Pull-In con Pelota de Ejercicio', 'abdominales', 'pelota de ejercicio', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Exercise_Ball_Pull-In/0.jpg', 'free-exercise-db'),
('Prensa de piso con kettlebell de un solo brazo de rango extendido.', 'pecho', 'pesas rusas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Extended_Range_One-Arm_Kettlebell_Floor_Press/0.jpg', 'free-exercise-db'),
('Rotación Externa', 'hombros', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/External_Rotation/0.jpg', 'free-exercise-db'),
('Rotación externa con banda', 'hombros', 'bandas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/External_Rotation_with_Band/0.jpg', 'free-exercise-db'),
('Rotación externa con cable', 'hombros', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/External_Rotation_with_Cable/0.jpg', 'free-exercise-db'),
('Elevación lateral de cuello.', 'hombros', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Face_Pull/0.jpg', 'free-exercise-db'),
('Caminata del granjero', 'antebrazos', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Farmers_Walk/0.jpg', 'free-exercise-db'),
('Salto rápido', 'cuádriceps', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Fast_Skipping/0.jpg', 'free-exercise-db'),
('Rizos de dedos', 'antebrazos', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Finger_Curls/0.jpg', 'free-exercise-db'),
('Vuelos de cables en banco plano', 'pecho', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Flat_Bench_Cable_Flyes/0.jpg', 'free-exercise-db'),
('Elevación de piernas en banco plano', 'abdominales', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Flat_Bench_Leg_Pull-In/0.jpg', 'free-exercise-db'),
('Elevación de piernas acostado en banco plano', 'abdominales', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Flat_Bench_Lying_Leg_Raise/0.jpg', 'free-exercise-db'),
('Flexor Curl de Mancuerna con Inclinación', 'bíceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Flexor_Incline_Dumbbell_Curls/0.jpg', 'free-exercise-db'),
('Elevación glútea en suelo.', 'isquiotibiales', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Floor_Glute-Ham_Raise/0.jpg', 'free-exercise-db'),
('Prensa de Banca', 'tríceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Floor_Press/0.jpg', 'free-exercise-db'),
('Press de piso con cadenas', 'tríceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Floor_Press_with_Chains/0.jpg', 'free-exercise-db'),
('Patadas de mariposa', 'glúteos', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Flutter_Kicks/0.jpg', 'free-exercise-db'),
('Pie-SMR', 'Las pantorrillas', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Foot-SMR/0.jpg', 'free-exercise-db'),
('Arrastrar hacia adelante con presión.', 'pecho', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Forward_Drag_with_Press/0.jpg', 'free-exercise-db'),
('Sentadilla Frankenstein', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Frankenstein_Squat/0.jpg', 'free-exercise-db'),
('Sentadilla con salto sin manos', 'cuádriceps', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Freehand_Jump_Squat/0.jpg', 'free-exercise-db'),
('Saltos de rana', 'cuádriceps', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Frog_Hops/0.jpg', 'free-exercise-db'),
('Abdominales de rana', 'abdominales', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Frog_Sit-Ups/0.jpg', 'free-exercise-db'),
('Sentadilla con barra al frente', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Front_Barbell_Squat/0.jpg', 'free-exercise-db'),
('Sentadilla frontal con barra sobre un banco', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Front_Barbell_Squat_To_A_Bench/0.jpg', 'free-exercise-db'),
('Salto a caja frontal', 'isquiotibiales', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Front_Box_Jump/0.jpg', 'free-exercise-db'),
('Elevación de cable frontal', 'hombros', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Front_Cable_Raise/0.jpg', 'free-exercise-db'),
('Saltos de cono frontal (o saltos de valla)', 'cuádriceps', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Front_Cone_Hops_or_hurdle_hops/0.jpg', 'free-exercise-db'),
('Levantamiento de mancuernas frontales', 'hombros', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Front_Dumbbell_Raise/0.jpg', 'free-exercise-db'),
('Elevación de mancuernas inclinada hacia adelante', 'hombros', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Front_Incline_Dumbbell_Raise/0.jpg', 'free-exercise-db'),
('Elevaciones de pierna delantera', 'isquiotibiales', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Front_Leg_Raises/0.jpg', 'free-exercise-db'),
('Elevación frontal de placa', 'hombros', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Front_Plate_Raise/0.jpg', 'free-exercise-db'),
('Elevación frontal y Pullover', 'pecho', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Front_Raise_And_Pullover/0.jpg', 'free-exercise-db'),
('Sentadilla frontal (agarre limpio)', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Front_Squat_Clean_Grip/0.jpg', 'free-exercise-db'),
('Sentadillas frontales con dos pesas rusas', 'cuádriceps', 'pesas rusas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Front_Squats_With_Two_Kettlebells/0.jpg', 'free-exercise-db'),
('Elevación frontal con dos mancuernas', 'hombros', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Front_Two-Dumbbell_Raise/0.jpg', 'free-exercise-db'),
('Polea alta con amplio rango de movimiento', 'Los lats', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Full_Range-Of-Motion_Lat_Pulldown/0.jpg', 'free-exercise-db'),
('Gironda Sternum Chins -> Dominadas de esternón de Gironda', 'Los lats', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Gironda_Sternum_Chins/0.jpg', 'free-exercise-db'),
('Elevación de Glúteos y Isquiotibiales', 'isquiotibiales', 'máquina', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Glute_Ham_Raise/0.jpg', 'free-exercise-db'),
('Patada de glúteos', 'glúteos', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Glute_Kickback/0.jpg', 'free-exercise-db'),
('Sentadilla con copa', 'cuádriceps', 'pesas rusas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Goblet_Squat/0.jpg', 'free-exercise-db'),
('Buenos días', 'isquiotibiales', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Good_Morning/0.jpg', 'free-exercise-db'),
('Buenos días de Pins', 'isquiotibiales', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Good_Morning_off_Pins/0.jpg', 'free-exercise-db'),
('Barbilla de gorila / Cereza de gorila', 'abdominales', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Gorilla_Chin_Crunch/0.jpg', 'free-exercise-db'),
('Estiramiento de ingle y espalda', 'aductores', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Groin_and_Back_Stretch/0.jpg', 'free-exercise-db'),
('Grohínos', 'aductores', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Groiners/0.jpg', 'free-exercise-db'),
('Sentadilla', 'cuádriceps', 'máquina', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hack_Squat/0.jpg', 'free-exercise-db'),
('Curls de martillo', 'bíceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hammer_Curls/0.jpg', 'free-exercise-db'),
('Press de banco inclinado con mancuernas con agarre de martillo', 'pecho', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hammer_Grip_Incline_DB_Bench_Press/0.jpg', 'free-exercise-db'),
('SMR de los isquiotibiales', 'isquiotibiales', 'rodillo de espuma', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hamstring-SMR/0.jpg', 'free-exercise-db'),
('Estiramiento de isquiotibiales', 'isquiotibiales', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hamstring_Stretch/0.jpg', 'free-exercise-db'),
('Flexiones en pino', 'hombros', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Handstand_Push-Ups/0.jpg', 'free-exercise-db'),
('Cargada de Potencia', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hang_Clean/0.jpg', 'free-exercise-db'),
('Arranque con colgada: por debajo de las rodillas.', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hang_Clean_-_Below_the_Knees/0.jpg', 'free-exercise-db'),
('Movimiento de halterofilia llamado "arrancada colgada".', 'isquiotibiales', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hang_Snatch/0.jpg', 'free-exercise-db'),
('Hang Snatch - Por debajo de las rodillas', 'isquiotibiales', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hang_Snatch_-_Below_Knees/0.jpg', 'free-exercise-db'),
('Barra para colgar Buenos días', 'isquiotibiales', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hanging_Bar_Good_Morning/0.jpg', 'free-exercise-db'),
('Elevación de piernas colgando', 'abdominales', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hanging_Leg_Raise/0.jpg', 'free-exercise-db'),
('Colgado Pike', 'abdominales', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hanging_Pike/0.jpg', 'free-exercise-db'),
('Balance de enganche pesado', 'cuádriceps', 'mancuerna', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Heaving_Snatch_Balance/0.jpg', 'free-exercise-db'),
('Embestida de bolsa pesada', 'pecho', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Heavy_Bag_Thrust/0.jpg', 'free-exercise-db'),
('Curls en Polea Alta', 'bíceps', 'cable', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/High_Cable_Curls/0.jpg', 'free-exercise-db'),
('Círculos de cadera (en posición prono)', 'secuestradores', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hip_Circles_prone/0.jpg', 'free-exercise-db'),
('Extensión de cadera con bandas.', 'glúteos', 'bandas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hip_Extension_with_Bands/0.jpg', 'free-exercise-db'),
('Flexión de cadera con banda', 'cuádriceps', 'bandas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hip_Flexion_with_Band/0.jpg', 'free-exercise-db'),
('Elevación de cadera con banda', 'glúteos', 'bandas', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hip_Lift_with_Band/0.jpg', 'free-exercise-db'),
('Abraza una pelota', 'espalda baja', 'pelota de ejercicio', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hug_A_Ball/0.jpg', 'free-exercise-db'),
('Abraza las rodillas al pecho.', 'espalda baja', NULL, 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hug_Knees_To_Chest/0.jpg', 'free-exercise-db'),
('Saltos de valla', 'isquiotibiales', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hurdle_Hops/0.jpg', 'free-exercise-db'),
('Hiperextensiones (Extensiones de espalda)', 'espalda baja', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hyperextensions_Back_Extensions/0.jpg', 'free-exercise-db'),
('Hiperextensiones sin banco de hiperextensión.', 'espalda baja', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hyperextensions_With_No_Hyperextension_Bench/0.jpg', 'free-exercise-db'),
('Estiramiento de la banda iliotibial y glúteos', 'secuestradores', 'otro', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/IT_Band_and_Glute_Stretch/0.jpg', 'free-exercise-db'),
('Tracto Iliotibial-SMR', 'secuestradores', 'rodillo de espuma', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Iliotibial_Tract-SMR/0.jpg', 'free-exercise-db'),
('Gusano medidor', 'isquiotibiales', 'solo cuerpo', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Inchworm/0.jpg', 'free-exercise-db');

