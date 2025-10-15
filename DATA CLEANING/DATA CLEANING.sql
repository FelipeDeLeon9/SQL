-- ============================================
-- LIMPIEZA DE DATOS - PROYECTO LAYOFFS
-- ============================================
-- Este script realiza una limpieza completa de datos siguiendo 4 pasos principales:
-- 1. Eliminar duplicados
-- 2. Estandarizar los datos
-- 3. Manejar valores nulos o en blanco
-- 4. Eliminar columnas o filas innecesarias

-- Consulta inicial para verificar los datos originales
SELECT *
FROM layoffs;

-- ============================================
-- PASO 1: ELIMINAR DUPLICADOS
-- ============================================

-- Crear una tabla de staging (copia de trabajo) con la misma estructura que la tabla original
-- Esto protege los datos originales durante el proceso de limpieza
CREATE TABLE layoffs_staging
LIKE layoffs;

-- Verificar que la tabla staging se creó correctamente
SELECT *
FROM layoffs_staging;

-- Copiar todos los datos de la tabla original a la tabla staging
INSERT layoffs_staging
SELECT *
FROM layoffs;

-- Identificar duplicados usando ROW_NUMBER() para numerar filas duplicadas
-- Se considera duplicado si todos estos campos son idénticos
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Crear un CTE (Common Table Expression) para identificar duplicados
-- Las filas con row_num > 1 son duplicadas
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
-- Consultar solo los duplicados para revisión
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Verificar un caso específico de duplicado (Casper) para validar la lógica
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

-- NOTA: No se puede hacer DELETE directamente en un CTE en MySQL
-- Por eso se crea una nueva tabla con una columna adicional para row_num
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
DELETE
FROM duplicate_cte
WHERE row_num > 1;

-- Crear una segunda tabla staging que incluye la columna row_num
-- Esta columna nos permitirá identificar y eliminar duplicados físicamente
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Verificar duplicados en la nueva tabla
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Insertar datos en layoffs_staging2 con el número de fila calculado
-- Esto marca todos los duplicados con row_num > 1
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Eliminar físicamente todas las filas duplicadas (mantiene solo la primera ocurrencia)
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- Verificar que los duplicados fueron eliminados correctamente
SELECT *
FROM layoffs_staging2;

-- ============================================
-- PASO 2: ESTANDARIZAR LOS DATOS
-- ============================================

-- 2.1 LIMPIAR ESPACIOS EN BLANCO EN COMPANY
-- Mostrar comparación entre el valor original y el valor con TRIM aplicado
SELECT company, TRIM(company)
FROM layoffs_staging2;

-- Aplicar TRIM para eliminar espacios en blanco al inicio y final
UPDATE layoffs_staging2
SET company = TRIM(company);

-- 2.2 ESTANDARIZAR LA COLUMNA INDUSTRY
-- Revisar todos los valores únicos de industry para identificar inconsistencias
SELECT DISTINCT industry
FROM layoffs_staging2;

-- Unificar todas las variaciones de "Crypto" (Crypto, CryptoCurrency, etc.) en un solo valor
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- 2.3 ESTANDARIZAR LA COLUMNA LOCATION
-- Revisar todas las ubicaciones únicas ordenadas alfabéticamente
SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;

-- Verificar registros con ubicación específica
SELECT *
FROM layoffs_staging2
WHERE location LIKE 'Malmo';

-- Corregir caracteres especiales mal codificados en nombres de ciudades
-- Florianópolis estaba mal codificado como FlorianÃ³polis
UPDATE layoffs_staging2
SET location = 'Florianopolis'
WHERE location = 'FlorianÃ³polis';

-- Düsseldorf estaba mal codificado como DÃ¼sseldorf
UPDATE layoffs_staging2
SET location = 'Dusseldorf'
WHERE location = 'DÃ¼sseldorf';

-- Malmö estaba mal codificado como MalmÃ¶
UPDATE layoffs_staging2
SET location = 'Malmo'
WHERE location = 'MalmÃ¶';

-- 2.4 ESTANDARIZAR LA COLUMNA COUNTRY
-- Revisar todos los países únicos
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

-- Verificar países con puntos al final (ej: "United States.")
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

-- Eliminar puntos al final del nombre del país
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- 2.5 ESTANDARIZAR LA COLUMNA DATE
-- Mostrar la fecha original y su conversión de texto a formato DATE
-- STR_TO_DATE convierte texto en formato mm/dd/yyyy a tipo DATE
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

-- Aplicar la conversión de fecha en toda la tabla
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Verificar que las fechas se convirtieron correctamente
SELECT `date`
FROM layoffs_staging2;

-- Cambiar el tipo de dato de la columna de TEXT a DATE
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- ============================================
-- PASO 3: MANEJAR VALORES NULL O EN BLANCO
-- ============================================

-- 3.1 IDENTIFICAR REGISTROS SIN INFORMACIÓN ÚTIL
-- Encontrar registros donde ambos campos críticos son NULL
-- Estos registros no aportan información sobre despidos
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- 3.2 LIMPIAR LA COLUMNA INDUSTRY
-- Encontrar registros con industry NULL o vacío
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

-- Verificar un caso específico (Bally's Interactive)
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';

-- Convertir strings vacíos a NULL para facilitar el manejo
-- Es mejor trabajar con NULL que con strings vacíos
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- 3.3 RELLENAR VALORES NULL DE INDUSTRY
-- Buscar registros de la misma empresa donde uno tiene industry y otro no
-- Esto permite rellenar datos faltantes usando información existente
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- Actualizar los valores NULL de industry usando datos de otros registros de la misma empresa
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Verificar los datos actualizados
SELECT *
FROM layoffs_staging2;

-- ============================================
-- PASO 4: ELIMINAR FILAS Y COLUMNAS INNECESARIAS
-- ============================================

-- 4.1 ELIMINAR REGISTROS SIN DATOS DE DESPIDOS
-- Revisar registros que no tienen información de despidos
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Eliminar registros sin datos útiles sobre despidos
-- Estos registros no aportan valor al análisis
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Verificar el resultado final de la limpieza
SELECT *
FROM layoffs_staging2;

-- 4.2 ELIMINAR COLUMNA AUXILIAR
-- Eliminar la columna row_num que solo se usó para identificar duplicados
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- ============================================
-- FIN DEL PROCESO DE LIMPIEZA
-- ============================================
-- La tabla layoffs_staging2 ahora contiene datos limpios y estandarizados,
-- listos para análisis y visualización
