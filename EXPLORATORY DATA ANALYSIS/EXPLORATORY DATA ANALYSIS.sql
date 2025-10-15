-- ============================================
-- ANÁLISIS EXPLORATORIO DE DATOS (EDA)
-- ============================================
-- Este script realiza un análisis exploratorio completo de los datos de despidos
-- para entender patrones, tendencias y obtener insights clave del dataset

-- ============================================
-- 1. EXPLORACIÓN INICIAL - VISTA GENERAL
-- ============================================

-- Consultar todos los datos limpios para una vista general inicial
SELECT *
FROM layoffs_staging2;

-- ============================================
-- 2. VALORES MÁXIMOS - IDENTIFICAR EXTREMOS
-- ============================================

-- Encontrar los valores máximos de despidos y porcentaje
-- MAX(total_laid_off): Mayor número de empleados despedidos en un solo evento
-- MAX(percentage_laid_off): Mayor porcentaje de la empresa despedido (1 = 100% = cierre total)
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

-- ============================================
-- 3. EMPRESAS QUE CERRARON COMPLETAMENTE
-- ============================================

-- Identificar empresas que despidieron al 100% de su personal (cerraron operaciones)
-- Ordenadas por fondos recaudados para ver qué empresas mejor financiadas cerraron
-- Esto muestra que tener mucho dinero no garantiza el éxito
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- ============================================
-- 4. DESPIDOS TOTALES POR EMPRESA
-- ============================================

-- Sumar todos los despidos realizados por cada empresa a lo largo del tiempo
-- Esto identifica las empresas con mayor impacto total en pérdida de empleos
-- ORDER BY 2 DESC ordena por la columna 2 (SUM) de mayor a menor
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- ============================================
-- 5. RANGO DE FECHAS DEL DATASET
-- ============================================

-- Identificar el periodo de tiempo que cubre el dataset
-- MIN(`date`): Primera fecha registrada
-- MAX(`date`): Última fecha registrada
-- Esto define el alcance temporal del análisis
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- ============================================
-- 6. DESPIDOS POR PAÍS
-- ============================================

-- Analizar qué países tuvieron mayor número de despidos
-- Esto muestra la distribución geográfica del impacto económico
-- Útil para entender qué mercados fueron más afectados
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- ============================================
-- 7. DESPIDOS POR AÑO
-- ============================================

-- Analizar la tendencia anual de despidos
-- YEAR(`date`) extrae el año de la fecha
-- Esto muestra cómo evolucionaron los despidos año tras año
-- ORDER BY 1 DESC ordena por año de más reciente a más antiguo
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- ============================================
-- 8. DESPIDOS POR ETAPA DE LA EMPRESA
-- ============================================

-- Analizar qué etapa empresarial (Seed, Series A, B, C, etc.) tuvo más despidos
-- Esto muestra si empresas en etapas tempranas o maduras fueron más afectadas
-- stage: Seed, Series A-F, Post-IPO, Acquired, etc.
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

-- ============================================
-- 9. DESPIDOS POR MES - TENDENCIA TEMPORAL
-- ============================================

-- Analizar despidos mes a mes para identificar patrones temporales
-- SUBSTRING(`date`,1,7) extrae "YYYY-MM" de la fecha (ej: "2023-01")
-- Esto permite ver picos y valles en la actividad de despidos
-- ORDER BY 1 ASC ordena cronológicamente de más antiguo a más reciente
SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC;

-- ============================================
-- 10. TOTAL ACUMULADO DE DESPIDOS (ROLLING TOTAL)
-- ============================================

-- Calcular el total acumulado de despidos mes a mes
-- Esto muestra cómo se van sumando los despidos a lo largo del tiempo
-- Es útil para visualizar la magnitud creciente del problema

-- CTE (Common Table Expression) que calcula despidos mensuales
WITH Rolling_Total AS
(
SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC
)
-- Calcular el total acumulado usando una función de ventana (WINDOW FUNCTION)
-- SUM() OVER(ORDER BY `MONTH`) suma todos los valores hasta la fila actual
SELECT `MONTH`, total_off,
SUM(total_off) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total;

-- ============================================
-- 11. DESPIDOS TOTALES POR EMPRESA (REPETIDO)
-- ============================================

-- Esta consulta es idéntica a la del paso 4
-- Muestra las empresas con más despidos totales acumulados
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- ============================================
-- 12. DESPIDOS POR EMPRESA Y AÑO
-- ============================================

-- Analizar despidos desglosados por empresa y año
-- Esto permite ver qué empresas tuvieron múltiples rondas de despidos
-- y en qué años fueron más severos
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;

-- ============================================
-- 13. RANKING TOP 5 EMPRESAS CON MÁS DESPIDOS POR AÑO
-- ============================================

-- Análisis avanzado: Identificar las 5 empresas con más despidos en cada año
-- Esto muestra los "peores casos" año tras año

-- Primer CTE: Calcular despidos por empresa y año
WITH Company_Year (company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
), 
-- Segundo CTE: Asignar ranking a cada empresa dentro de su año
-- DENSE_RANK(): Asigna posiciones sin saltos (1,2,3,4,5...)
-- PARTITION BY years: Crea rankings separados para cada año
-- ORDER BY total_laid_off DESC: Ordena de mayor a menor despidos
Company_Year_Rank AS
(SELECT *, 
DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
WHERE years IS NOT NULL
)
-- Filtrar solo el Top 5 de cada año
-- Esto permite comparar las empresas más afectadas año tras año
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5;

-- ============================================
-- FIN DEL ANÁLISIS EXPLORATORIO
-- ============================================
-- Este análisis proporciona insights sobre:
-- - Magnitud de los despidos (valores máximos)
-- - Empresas más afectadas (por total y por año)
-- - Distribución geográfica (por país)
-- - Tendencias temporales (por año y mes)
-- - Etapas empresariales más vulnerables
-- - Evolución acumulada del problema
-- - Rankings y comparaciones interanuales
