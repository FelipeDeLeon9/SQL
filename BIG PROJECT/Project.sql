-- Crear la nueva base de datos
CREATE DATABASE IngramBI;
GO

USE IngramBI;
GO

-- Crear schema de dimensiones
CREATE SCHEMA dim;
GO

-- Crear schema de hechos
CREATE SCHEMA fact;
GO

-- Crear schema de operaciones (tickets)
CREATE SCHEMA ops;
GO

USE IngramBI;
GO

-- Despues de ingresar las bases de datos en formato CSV, se revisa que las bases de datos tengan todos los datos ok y completos

SELECT *
FROM dim.Calendar;

SELECT *
FROM dim.Products;

SELECT *
FROM dim.Customers;

SELECT *
FROM fact.Sales;

SELECT *
FROM ops.Tickets;
GO

-- Revisar los valores de la columna SLA_Met
SELECT SLA_Met, COUNT(*) AS Cantidad
FROM ops.Tickets
GROUP BY SLA_Met;
GO


-- Este código actualizó los valores de la columna SLA_Met en la tabla ops.Tickets, asegurando que solo tenga 1 o 0.
UPDATE ops.Tickets
SET SLA_Met = CASE 
              WHEN SLA_Met = 1 THEN 1 
              ELSE 0 
END;
GO

-- Codigo para cambiar el tipo de columna de int a booleano
ALTER TABLE ops.Tickets
ALTER COLUMN SLA_Met bit;
GO

-- Índices sobre fact.Sales
CREATE INDEX IX_salesfact_OrderDate_Channel
ON fact.Sales (OrderDate, Channel)
INCLUDE (LineAmount, Qty, DiscountPct, UnitPrice, ListPrice, ProductID, CustomerID);

CREATE INDEX IX_salesfact_Customer
ON fact.Sales (CustomerID)
INCLUDE (LineAmount, OrderDate);

CREATE INDEX IX_salesfact_Product
ON fact.Sales (ProductID)
INCLUDE (LineAmount, OrderDate);

-- Índice sobre ops.Tickets
CREATE INDEX IX_Tickets_Priority_Region
ON ops.Tickets (Priority, Region)
INCLUDE (SLA_Met);
GO

-- ANALISIS EXPLORATORIO INICIAL:

-- 1. RESUMEN GENERAL DE DATOS
SELECT 
    'Productos' AS Tabla, COUNT(*) AS Registros FROM dim.Products
UNION ALL
SELECT 'Clientes', COUNT(*) FROM dim.Customers
UNION ALL
SELECT 'Calendario', COUNT(*) FROM dim.Calendar
UNION ALL
SELECT 'Ventas', COUNT(*) FROM fact.Sales
UNION ALL
SELECT 'Tickets', COUNT(*) FROM ops.Tickets;

-- 2. PERÍODO DE ANÁLISIS DE VENTAS
SELECT 
    MIN(OrderDate) AS PrimeraVenta,
    MAX(OrderDate) AS ÚltimaVenta,
    DATEDIFF(day, MIN(OrderDate), MAX(OrderDate)) AS DíasDeOperación
FROM fact.Sales;

-- 3. PERÍODO DE ANÁLISIS DE TICKETS
SELECT 
    MIN(CreatedAt) AS PrimerTicket,
    MAX(CreatedAt) AS ÚltimoTicket,
    DATEDIFF(day, MIN(CreatedAt), MAX(CreatedAt)) AS DíasDeOperación
FROM ops.Tickets;
GO

-- Queries para el analisis de ventas y generacion de insights apartir de ellos.

-- MÉTRICAS CLAVES DEL NEGOCIO
-- (Total de ordenes, Clientes activos, Productos Vendidos, Unidades Vendidas, Ventas Totales (Bruto) Tickets Promedio)
SELECT
    FORMAT(COUNT(DISTINCT OrderID),  'N0', 'es-CO') AS Total_Ordenes,
    FORMAT(COUNT(DISTINCT CustomerID),'N0', 'es-CO') AS Clientes_Activos,
    FORMAT(COUNT(DISTINCT ProductID), 'N0', 'es-CO') AS Productos_Vendidos,

    FORMAT(SUM(Qty),            'N0', 'es-CO') AS Unidades_Vendidas,
    FORMAT(AVG(LineAmount),     'N0', 'es-CO') AS Tickets_Promedio,
    FORMAT(SUM(LineAmount),     'C0', 'es-CO') AS VentasTotales_Bruta
FROM fact.Sales;
GO

--VENTAS X CANAL
SELECT
    Channel AS Canal,
    COUNT(DISTINCT OrderID) AS Ordenes,
    FORMAT(
        SUM(CASE WHEN IsReturn = 0 AND IsCancelled = 0 THEN LineAmount ELSE 0 END),
        'C0', 'es-CO'
    ) AS Ventas_Netas,
    FORMAT(AVG(LineAmount), 'N0', 'es-CO') AS Tickets_Promedio,
    FORMAT(SUM(Qty), 'N0', 'es-CO')        AS Unidades_Vendidas
FROM fact.Sales
GROUP BY Channel
ORDER BY
    SUM(CASE WHEN IsReturn = 0 AND IsCancelled = 0 THEN LineAmount ELSE 0 END) DESC;
GO


-- TOP 10 PRODUCTOS ESTRELLA X INGRESOS
SELECT TOP 10
    p.ProductName AS Producto,
    p.Category    AS Categoria,
    p.Brand       AS Marca,
    FORMAT(
        SUM(CASE WHEN s.IsReturn = 0 AND s.IsCancelled = 0 THEN s.LineAmount ELSE 0 END),
        'C0',
        'es-CO'
    ) AS Ventas_Neta
FROM fact.Sales s
JOIN dim.Products p ON s.ProductID = p.ProductID
GROUP BY p.ProductName, p.Category, p.Brand
ORDER BY 
    SUM(CASE WHEN s.IsReturn = 0 AND s.IsCancelled = 0 THEN s.LineAmount ELSE 0 END) DESC; -- ordena por valor real
GO

-- TOP 5 CLIENTES MAS VALIOSOS
SELECT TOP 5
    c.CustomerName AS Cliente,
    c.Region       AS Región,
    c.Segment      AS Segmento,
    COUNT(DISTINCT s.OrderID) AS Total_Ordenes,
    SUM(s.Qty)                AS Unidades_Compradas,

    -- $ COP con separador de miles (sin decimales)
    FORMAT(
        SUM(CASE WHEN s.IsReturn = 0 AND s.IsCancelled = 0 THEN s.LineAmount ELSE 0 END),
        'C0', 'es-CO'
    ) AS Ventas_Neta,

    -- Número sin decimales
    FORMAT(AVG(s.LineAmount), 'N0', 'es-CO') AS TicketPromedio,

    CONVERT(varchar(10), MAX(s.OrderDate), 23) AS Última_Compra,  -- YYYY-MM-DD
    DATEDIFF(day, MAX(s.OrderDate), GETDATE()) AS Días_Sin_Comprar
FROM fact.Sales s
INNER JOIN dim.Customers c ON s.CustomerID = c.CustomerID
GROUP BY c.CustomerName, c.Region, c.Segment
ORDER BY
    SUM(CASE WHEN s.IsReturn = 0 AND s.IsCancelled = 0 THEN s.LineAmount ELSE 0 END) DESC;
GO

-- PERFORMANCE X REGION
SELECT
    c.Region AS Región,
    COUNT(DISTINCT c.CustomerID) AS Clientes,
    COUNT(DISTINCT s.OrderID)    AS Órdenes,
    FORMAT(
        SUM(CASE WHEN s.IsReturn = 0 AND s.IsCancelled = 0 THEN s.LineAmount ELSE 0 END),
        'C0','es-CO'
    ) AS VentaNeta,                     
    FORMAT(AVG(s.LineAmount), 'N0','es-CO') AS TicketPromedio,  
    FORMAT(SUM(s.Qty),        'N0','es-CO') AS UnidadesVendidas  
FROM fact.Sales s
INNER JOIN dim.Customers c ON s.CustomerID = c.CustomerID
GROUP BY c.Region
ORDER BY
    SUM(CASE WHEN s.IsReturn = 0 AND s.IsCancelled = 0 THEN s.LineAmount ELSE 0 END) DESC;  
GO

--TENDECIA DE VENTAS POR MES
SELECT
    cal.Year      AS Año,
    cal.Month     AS Mes,
    cal.MonthName AS NombreMes,

    FORMAT(COUNT(DISTINCT s.OrderID), 'N0', 'es-CO') AS Órdenes,
    FORMAT(SUM(s.Qty),        'N0', 'es-CO') AS Unidades_Vendidas,
    FORMAT(AVG(s.LineAmount), 'N0', 'es-CO') AS Tickets_Promedio,
    FORMAT(
        SUM(CASE WHEN s.IsReturn = 0 AND s.IsCancelled = 0 THEN s.LineAmount ELSE 0 END),
        'C0', 'es-CO'
    ) AS Ventas_Neta
FROM fact.Sales s
INNER JOIN dim.Calendar cal
    ON CAST(s.OrderDate AS date) = cal.Date
GROUP BY cal.Year, cal.Month, cal.MonthName
ORDER BY cal.Year, cal.Month;
GO

-- IMPACTO DE DESCUENTOS EN VOLUMEN DE VENTAS
SELECT
    CASE
        WHEN DiscountPct = 0  THEN 'Sin Descuento'
        WHEN DiscountPct <= 10 THEN '1–10%'
        WHEN DiscountPct <= 20 THEN '11–20%'
        WHEN DiscountPct <= 30 THEN '21–30%'
        ELSE 'Más de 30%'
    END AS Rangos_Descuento,

    FORMAT(COUNT(DISTINCT OrderID), 'N0', 'es-CO') AS Ordenes,
    FORMAT(SUM(Qty),              'N0', 'es-CO') AS Unidades_Vendidas
FROM fact.Sales
GROUP BY
    CASE
        WHEN DiscountPct = 0  THEN 'Sin Descuento'
        WHEN DiscountPct <= 10 THEN '1–10%'
        WHEN DiscountPct <= 20 THEN '11–20%'
        WHEN DiscountPct <= 30 THEN '21–30%'
        ELSE 'Más de 30%'
    END
ORDER BY AVG(DiscountPct);   -- ordena por el valor numérico real del descuento
GO


-- ANALISIS DE TICKETS
-- MÉTRICAS CLAVE DEL SERVICIO (Total de tickets, Promedio hr resolución, Menor tiempo, Mayor tiempo,% Cumplimiento de SLA)
SELECT
    FORMAT(COUNT(*), 'N0', 'es-CO')                                       AS TotalTickets,
    FORMAT(AVG(CAST(Resolution_Hours AS float)), 'N2', 'es-CO')           AS PromedioHorasResolucion,
    FORMAT(MIN(Resolution_Hours), 'N0', 'es-CO')                          AS MenorTiempoResolucion_hrs,
    FORMAT(MAX(Resolution_Hours), 'N0', 'es-CO')                          AS MayorTiempoResolucion_hrs,
    FORMAT(AVG(CASE WHEN SLA_Met = 1 THEN 1.0 ELSE 0.0 END), 'P2','es-CO') AS PorcentajeCumplimientoSLA
FROM ops.Tickets;


-- PERFORMANCE POR NIVEL DE PRIORIDAD
SELECT
    Priority AS Prioridad,
    FORMAT(COUNT(*), 'N0', 'es-CO')                           AS TotalTickets,          
    FORMAT(AVG(CASE WHEN SLA_Met = 1 THEN 1.0 ELSE 0.0 END),
           'P2', 'es-CO')                                     AS PorcentajeCumplimientoSLA  
FROM ops.Tickets
GROUP BY Priority
ORDER BY CASE LOWER(Priority)
           WHEN 'critical' THEN 1
           WHEN 'high'    THEN 2
           WHEN 'medium'  THEN 3
           WHEN 'low'     THEN 4
           ELSE 5
         END;
GO

--TENDENCIA DE TICKETS POR MES
SELECT
    YEAR(CreatedAt)  AS Año,
    MONTH(CreatedAt) AS Mes,
    FORMAT(COUNT(*), 'N0', 'es-CO') AS TotalTickets,        
    FORMAT(
        AVG(CASE WHEN SLA_Met = 1 THEN 1.0 ELSE 0.0 END), 
        'P2', 'es-CO'
    ) AS CumplimientoSLA                                        
FROM ops.Tickets
GROUP BY YEAR(CreatedAt), MONTH(CreatedAt)
ORDER BY Año, Mes;


--ANALISIS CRUZADOS(VENTAS + TICKETS)
WITH VentasPorRegion AS (
    SELECT 
        c.Region,
        COUNT(DISTINCT s.OrderID) AS TotalÓrdenes,
        SUM(CASE WHEN s.IsReturn = 0 AND s.IsCancelled = 0 THEN s.LineAmount ELSE 0 END) AS VentaNeta
    FROM fact.Sales s
    INNER JOIN dim.Customers c ON s.CustomerID = c.CustomerID
    GROUP BY c.Region
),
TicketsPorRegion AS (
    SELECT 
        Region,
        COUNT(*) AS TotalTickets,
        AVG(Resolution_Hours) AS PromedioResolución,
        CAST(SUM(CASE WHEN SLA_Met = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100 AS CumplimientoSLA
    FROM ops.Tickets
    GROUP BY Region
)
SELECT 
    v.Region AS Región,
    v.TotalÓrdenes AS Órdenes,
    v.VentaNeta AS VentaNeta,
    t.TotalTickets AS Tickets,
    CAST(t.TotalTickets AS FLOAT) / v.TotalÓrdenes AS TicketsPorOrden,
    t.PromedioResolución AS HorasPromedioResolución,
    t.CumplimientoSLA AS PorcentajeSLA
FROM VentasPorRegion v
LEFT JOIN TicketsPorRegion t ON v.Region = t.Region
ORDER BY v.VentaNeta DESC;

--RENTABILIDAD POR CLIENTE
WITH ClienteRFM AS (
    SELECT 
        c.CustomerID,
        c.CustomerName,
        c.Region,
        c.Segment,
        DATEDIFF(day, MAX(s.OrderDate), GETDATE()) AS DíasSinComprar,                -- Recency
        COUNT(DISTINCT s.OrderID) AS TotalÓrdenes,                                    -- Frequency
        SUM(CASE WHEN s.IsReturn = 0 AND s.IsCancelled = 0 THEN s.LineAmount ELSE 0 END) AS VentaNetaTotal, -- Monetary
        AVG(s.LineAmount) AS TicketPromedio,
        CAST(SUM(CASE WHEN s.IsReturn = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100 AS TasaDevolución
    FROM dim.Customers c
    INNER JOIN fact.Sales s ON c.CustomerID = s.CustomerID
    GROUP BY c.CustomerID, c.CustomerName, c.Region, c.Segment
),
ClienteTickets AS (
    SELECT 
        c.CustomerID,
        COUNT(t.TicketID) AS TotalTickets,
        AVG(t.Resolution_Hours) AS PromedioHorasResolución,
        SUM(CASE WHEN t.SLA_Met = 0 THEN 1 ELSE 0 END) AS TicketsSLAIncumplido,
        SUM(t.Resolution_Hours) * 50 AS CostoSoporteEstimado
    FROM dim.Customers c
    LEFT JOIN fact.Sales s ON c.CustomerID = s.CustomerID
    LEFT JOIN ops.Tickets t 
      ON c.Region = t.Region 
     AND CAST(s.OrderDate AS date) = CAST(t.CreatedAt AS date)
    GROUP BY c.CustomerID
),
Segmentacion AS (
    SELECT 
        r.*,
        ISNULL(t.TotalTickets, 0) AS TotalTickets,
        ISNULL(t.PromedioHorasResolución, 0) AS HorasResolución,
        ISNULL(t.TicketsSLAIncumplido, 0) AS SLAIncumplidos,
        ISNULL(t.CostoSoporteEstimado, 0) AS CostoSoporte,
        r.VentaNetaTotal - ISNULL(t.CostoSoporteEstimado, 0) AS RentabilidadNeta,
        CASE 
            WHEN r.DíasSinComprar <= 30 THEN 'Activo'
            WHEN r.DíasSinComprar <= 90 THEN 'En Riesgo'
            ELSE 'Inactivo'
        END AS EstadoRecencia,
        CASE 
            WHEN r.TotalÓrdenes >= 10 THEN 'Alto'
            WHEN r.TotalÓrdenes >= 5  THEN 'Medio'
            ELSE 'Bajo'
        END AS NivelFrecuencia,
        CASE 
            WHEN r.VentaNetaTotal >= 100000 THEN 'Premium'
            WHEN r.VentaNetaTotal >=  50000 THEN 'Gold'
            WHEN r.VentaNetaTotal >=  10000 THEN 'Silver'
            ELSE 'Bronze'
        END AS TierValor
    FROM ClienteRFM r
    LEFT JOIN ClienteTickets t ON r.CustomerID = t.CustomerID
)
SELECT 
    s.CustomerName AS Cliente,
    s.Region       AS Region,
    s.Segment      AS Segmento,
    s.TierValor    AS Tier,

    FORMAT(s.TotalÓrdenes,     'N0', 'es-CO') AS Ordenes,
    s.NivelFrecuencia          AS Frecuencia,
    FORMAT(s.DíasSinComprar,   'N0', 'es-CO') AS DiasSinCompra,
    FORMAT(s.TotalTickets,     'N0', 'es-CO') AS Tickets,
    FORMAT(s.SLAIncumplidos,   'N0', 'es-CO') AS SLA_Fallidos,
    FORMAT(s.HorasResolución,  'N0', 'es-CO') AS Horas_de_Soporte,

    FORMAT(s.VentaNetaTotal,   'C0', 'es-CO') AS VentaTotal,
    FORMAT(s.CostoSoporte,     'C0', 'es-CO') AS CostoSoporte,
    FORMAT(s.RentabilidadNeta, 'C0', 'es-CO') AS RentabilidadNeta
FROM Segmentacion s
ORDER BY s.RentabilidadNeta DESC;
GO
