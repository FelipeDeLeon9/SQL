-- ============================================================================
-- INGRAMBI DATABASE INITIAL CONFIGURATION
-- ============================================================================
-- Business Intelligence System for sales analysis and support tickets
-- Author: Felipe De León
-- Date: 10/15/2025
-- ============================================================================

-- Create new database for BI system
CREATE DATABASE IngramBI;
GO

-- Select the newly created database
USE IngramBI;
GO

-- ============================================================================
-- SCHEMA CREATION FOR LOGICAL ORGANIZATION
-- ============================================================================

-- Schema for dimension tables (master data)
CREATE SCHEMA dim;
GO

-- Schema for fact tables (transactions)
CREATE SCHEMA fact;
GO

-- Schema for operations and support tickets
CREATE SCHEMA ops;
GO

USE IngramBI;
GO

-- ============================================================================
-- DATA LOAD VERIFICATION
-- ============================================================================
-- After importing CSV files, verify all tables

-- Verify calendar table (time dimension)
SELECT *
FROM dim.Calendar;

-- Verify product catalog
SELECT *
FROM dim.Products;

-- Verify customer catalog
SELECT *
FROM dim.Customers;

-- Verify sales fact table
SELECT *
FROM fact.Sales;

-- Verify support tickets table
SELECT *
FROM ops.Tickets;
GO

-- ============================================================================
-- DATA CLEANING AND TRANSFORMATION
-- ============================================================================

-- Review value distribution in SLA_Met column
-- Allows identification of incorrect or inconsistent values
SELECT SLA_Met, COUNT(*) AS Cantidad
FROM ops.Tickets
GROUP BY SLA_Met;
GO

-- Standardize SLA_Met column to contain only values 1 or 0
-- Converts any value other than 1 to 0
UPDATE ops.Tickets
SET SLA_Met = CASE 
              WHEN SLA_Met = 1 THEN 1 
              ELSE 0 
END;
GO

-- Change SLA_Met data type from INT to BIT (boolean)
-- Optimizes storage and makes the binary nature of the field clear
ALTER TABLE ops.Tickets
ALTER COLUMN SLA_Met bit;
GO

-- ============================================================================
-- INDEX CREATION FOR QUERY OPTIMIZATION
-- ============================================================================

-- Composite index on fact.Sales for queries by date and channel
-- INCLUDE adds columns at leaf level to avoid lookups
CREATE INDEX IX_salesfact_OrderDate_Channel
ON fact.Sales (OrderDate, Channel)
INCLUDE (LineAmount, Qty, DiscountPct, UnitPrice, ListPrice, ProductID, CustomerID);

-- Index on fact.Sales for queries by customer
-- Optimizes JOINs and aggregations by CustomerID
CREATE INDEX IX_salesfact_Customer
ON fact.Sales (CustomerID)
INCLUDE (LineAmount, OrderDate);

-- Index on fact.Sales for queries by product
-- Optimizes product and category analysis
CREATE INDEX IX_salesfact_Product
ON fact.Sales (ProductID)
INCLUDE (LineAmount, OrderDate);

-- Composite index on ops.Tickets for priority analysis by region
-- Facilitates SLA compliance reports by segments
CREATE INDEX IX_Tickets_Priority_Region
ON ops.Tickets (Priority, Region)
INCLUDE (SLA_Met);
GO

-- ============================================================================
-- INITIAL EXPLORATORY ANALYSIS
-- ============================================================================

-- 1. GENERAL SUMMARY OF RECORDS IN ALL TABLES
-- Provides a quick view of data volume in the system
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

-- 2. SALES ANALYSIS PERIOD
-- Identifies the time range of sales transactions
SELECT 
    MIN(OrderDate) AS PrimeraVenta,
    MAX(OrderDate) AS ÚltimaVenta,
    DATEDIFF(day, MIN(OrderDate), MAX(OrderDate)) AS DíasDeOperación
FROM fact.Sales;

-- 3. TICKETS ANALYSIS PERIOD
-- Identifies the time range of support tickets
SELECT 
    MIN(CreatedAt) AS PrimerTicket,
    MAX(CreatedAt) AS ÚltimoTicket,
    DATEDIFF(day, MIN(CreatedAt), MAX(CreatedAt)) AS DíasDeOperación
FROM ops.Tickets;
GO

-- ============================================================================
-- SALES ANALYSIS - KEY BUSINESS METRICS
-- ============================================================================

-- MAIN BUSINESS KPIS
-- Fundamental metrics: orders, customers, products, units and total sales
SELECT
    FORMAT(COUNT(DISTINCT OrderID),  'N0', 'es-CO') AS Total_Ordenes,
    FORMAT(COUNT(DISTINCT CustomerID),'N0', 'es-CO') AS Clientes_Activos,
    FORMAT(COUNT(DISTINCT ProductID), 'N0', 'es-CO') AS Productos_Vendidos,
    FORMAT(SUM(Qty),            'N0', 'es-CO') AS Unidades_Vendidas,
    FORMAT(AVG(LineAmount),     'N0', 'es-CO') AS Tickets_Promedio,
    FORMAT(SUM(LineAmount),     'C0', 'es-CO') AS VentasTotales_Bruta
FROM fact.Sales;
GO

-- PERFORMANCE BY SALES CHANNEL
-- Analyzes performance of each channel (Online, Retail, Distributor)
-- Excludes returns and cancellations to calculate net sales
SELECT
    Channel AS Canal,
    COUNT(DISTINCT OrderID) AS Ordenes,
    -- Net sales: excludes returned or cancelled transactions
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

-- TOP 10 STAR PRODUCTS BY REVENUE
-- Identifies the most profitable products in the catalog
-- Useful for inventory and marketing strategies
SELECT TOP 10
    p.ProductName AS Producto,
    p.Category    AS Categoria,
    p.Brand       AS Marca,
    -- Calculates net sales excluding returns and cancellations
    FORMAT(
        SUM(CASE WHEN s.IsReturn = 0 AND s.IsCancelled = 0 THEN s.LineAmount ELSE 0 END),
        'C0',
        'es-CO'
    ) AS Ventas_Neta
FROM fact.Sales s
JOIN dim.Products p ON s.ProductID = p.ProductID
GROUP BY p.ProductName, p.Category, p.Brand
ORDER BY 
    SUM(CASE WHEN s.IsReturn = 0 AND s.IsCancelled = 0 THEN s.LineAmount ELSE 0 END) DESC;
GO

-- TOP 5 MOST VALUABLE CUSTOMERS
-- VIP customer analysis for retention strategies
-- Includes recency metrics (days without purchase)
SELECT TOP 5
    c.CustomerName AS Cliente,
    c.Region       AS Región,
    c.Segment      AS Segmento,
    COUNT(DISTINCT s.OrderID) AS Total_Ordenes,
    SUM(s.Qty)                AS Unidades_Compradas,
    -- Net sales without returns or cancellations
    FORMAT(
        SUM(CASE WHEN s.IsReturn = 0 AND s.IsCancelled = 0 THEN s.LineAmount ELSE 0 END),
        'C0', 'es-CO'
    ) AS Ventas_Neta,
    FORMAT(AVG(s.LineAmount), 'N0', 'es-CO') AS TicketPromedio,
    -- Last purchase date in ISO format (YYYY-MM-DD)
    CONVERT(varchar(10), MAX(s.OrderDate), 23) AS Última_Compra,
    -- Recency metric: days elapsed since last purchase
    DATEDIFF(day, MAX(s.OrderDate), GETDATE()) AS Días_Sin_Comprar
FROM fact.Sales s
INNER JOIN dim.Customers c ON s.CustomerID = c.CustomerID
GROUP BY c.CustomerName, c.Region, c.Segment
ORDER BY
    SUM(CASE WHEN s.IsReturn = 0 AND s.IsCancelled = 0 THEN s.LineAmount ELSE 0 END) DESC;
GO

-- PERFORMANCE BY GEOGRAPHIC REGION
-- Compares commercial performance in different regions
-- Allows identification of strong markets and growth opportunities
SELECT
    c.Region AS Región,
    COUNT(DISTINCT c.CustomerID) AS Clientes,
    COUNT(DISTINCT s.OrderID)    AS Órdenes,
    -- Net sales by region
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

-- SALES TREND BY MONTH
-- Temporal analysis to identify seasonality and trends
-- Useful for forecasting and inventory planning
SELECT
    cal.Year      AS Año,
    cal.Month     AS Mes,
    cal.MonthName AS NombreMes,
    FORMAT(COUNT(DISTINCT s.OrderID), 'N0', 'es-CO') AS Órdenes,
    FORMAT(SUM(s.Qty),        'N0', 'es-CO') AS Unidades_Vendidas,
    FORMAT(AVG(s.LineAmount), 'N0', 'es-CO') AS Tickets_Promedio,
    -- Monthly net sales
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

-- DISCOUNT IMPACT ON SALES VOLUME
-- Analyzes effectiveness of discount strategies
-- Groups transactions by applied discount ranges
SELECT
    -- Discount categorization into ranges
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
ORDER BY AVG(DiscountPct);
GO

-- ============================================================================
-- SUPPORT TICKETS ANALYSIS
-- ============================================================================

-- KEY CUSTOMER SERVICE METRICS
-- Main KPIs: volume, resolution times and SLA compliance
SELECT
    FORMAT(COUNT(*), 'N0', 'es-CO') AS TotalTickets,
    -- Average hours to resolve tickets
    FORMAT(AVG(CAST(Resolution_Hours AS float)), 'N2', 'es-CO') AS PromedioHorasResolucion,
    FORMAT(MIN(Resolution_Hours), 'N0', 'es-CO') AS MenorTiempoResolucion_hrs,
    FORMAT(MAX(Resolution_Hours), 'N0', 'es-CO') AS MayorTiempoResolucion_hrs,
    -- Percentage of tickets resolved within SLA
    FORMAT(AVG(CASE WHEN SLA_Met = 1 THEN 1.0 ELSE 0.0 END), 'P2','es-CO') AS PorcentajeCumplimientoSLA
FROM ops.Tickets;

-- PERFORMANCE BY PRIORITY LEVEL
-- Analyzes SLA compliance according to ticket urgency
-- Orders from highest to lowest criticality
SELECT
    Priority AS Prioridad,
    FORMAT(COUNT(*), 'N0', 'es-CO') AS TotalTickets,          
    -- SLA compliance rate by priority
    FORMAT(AVG(CASE WHEN SLA_Met = 1 THEN 1.0 ELSE 0.0 END),
           'P2', 'es-CO') AS PorcentajeCumplimientoSLA  
FROM ops.Tickets
GROUP BY Priority
-- Custom ordering by priority level
ORDER BY CASE LOWER(Priority)
           WHEN 'critical' THEN 1
           WHEN 'high'    THEN 2
           WHEN 'medium'  THEN 3
           WHEN 'low'     THEN 4
           ELSE 5
         END;
GO

-- TICKET TREND BY MONTH
-- Identifies temporal patterns in ticket generation
-- Useful for sizing support teams
SELECT
    YEAR(CreatedAt)  AS Año,
    MONTH(CreatedAt) AS Mes,
    FORMAT(COUNT(*), 'N0', 'es-CO') AS TotalTickets,        
    -- Monthly SLA compliance
    FORMAT(
        AVG(CASE WHEN SLA_Met = 1 THEN 1.0 ELSE 0.0 END), 
        'P2', 'es-CO'
    ) AS CumplimientoSLA                                        
FROM ops.Tickets
GROUP BY YEAR(CreatedAt), MONTH(CreatedAt)
ORDER BY Año, Mes;

-- ============================================================================
-- CROSS ANALYSIS: SALES + TICKETS
-- ============================================================================

-- CORRELATION BETWEEN SALES AND SUPPORT BY REGION
-- Relates commercial activity with technical support demand
-- Identifies regions with high service load vs. sales
WITH VentasPorRegion AS (
    -- Calculate sales metrics by region
    SELECT 
        c.Region,
        COUNT(DISTINCT s.OrderID) AS TotalÓrdenes,
        SUM(CASE WHEN s.IsReturn = 0 AND s.IsCancelled = 0 THEN s.LineAmount ELSE 0 END) AS VentaNeta
    FROM fact.Sales s
    INNER JOIN dim.Customers c ON s.CustomerID = c.CustomerID
    GROUP BY c.Region
),
TicketsPorRegion AS (
    -- Calculate support metrics by region
    SELECT 
        Region,
        COUNT(*) AS TotalTickets,
        AVG(Resolution_Hours) AS PromedioResolución,
        CAST(SUM(CASE WHEN SLA_Met = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100 AS CumplimientoSLA
    FROM ops.Tickets
    GROUP BY Region
)
-- Combine both metrics for comprehensive analysis
SELECT 
    v.Region AS Región,
    v.TotalÓrdenes AS Órdenes,
    v.VentaNeta AS VentaNeta,
    t.TotalTickets AS Tickets,
    -- Ticket per order ratio (quality/complexity indicator)
    CAST(t.TotalTickets AS FLOAT) / v.TotalÓrdenes AS TicketsPorOrden,
    t.PromedioResolución AS HorasPromedioResolución,
    t.CumplimientoSLA AS PorcentajeSLA
FROM VentasPorRegion v
LEFT JOIN TicketsPorRegion t ON v.Region = t.Region
ORDER BY v.VentaNeta DESC;

-- ============================================================================
-- ADVANCED ANALYSIS: PROFITABILITY AND RFM SEGMENTATION
-- ============================================================================

-- COMPREHENSIVE PROFITABILITY ANALYSIS BY CUSTOMER
-- Implements RFM model (Recency, Frequency, Monetary)
-- Includes support costs to calculate net profitability
WITH ClienteRFM AS (
    -- CTE 1: Calculate RFM metrics per customer
    SELECT 
        c.CustomerID,
        c.CustomerName,
        c.Region,
        c.Segment,
        -- Recency: days since last purchase
        DATEDIFF(day, MAX(s.OrderDate), GETDATE()) AS DíasSinComprar,
        -- Frequency: number of orders
        COUNT(DISTINCT s.OrderID) AS TotalÓrdenes,
        -- Monetary: total net purchase value
        SUM(CASE WHEN s.IsReturn = 0 AND s.IsCancelled = 0 THEN s.LineAmount ELSE 0 END) AS VentaNetaTotal,
        AVG(s.LineAmount) AS TicketPromedio,
        -- Return rate as satisfaction indicator
        CAST(SUM(CASE WHEN s.IsReturn = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100 AS TasaDevolución
    FROM dim.Customers c
    INNER JOIN fact.Sales s ON c.CustomerID = s.CustomerID
    GROUP BY c.CustomerID, c.CustomerName, c.Region, c.Segment
),
ClienteTickets AS (
    -- CTE 2: Calculate support costs per customer
    SELECT 
        c.CustomerID,
        COUNT(t.TicketID) AS TotalTickets,
        AVG(t.Resolution_Hours) AS PromedioHorasResolución,
        SUM(CASE WHEN t.SLA_Met = 0 THEN 1 ELSE 0 END) AS TicketsSLAIncumplido,
        -- Cost estimation: $50 per support hour
        SUM(t.Resolution_Hours) * 50 AS CostoSoporteEstimado
    FROM dim.Customers c
    LEFT JOIN fact.Sales s ON c.CustomerID = s.CustomerID
    LEFT JOIN ops.Tickets t 
      ON c.Region = t.Region 
     AND CAST(s.OrderDate AS date) = CAST(t.CreatedAt AS date)
    GROUP BY c.CustomerID
),
Segmentacion AS (
    -- CTE 3: Combine metrics and create strategic segmentations
    SELECT 
        r.*,
        ISNULL(t.TotalTickets, 0) AS TotalTickets,
        ISNULL(t.PromedioHorasResolución, 0) AS HorasResolución,
        ISNULL(t.TicketsSLAIncumplido, 0) AS SLAIncumplidos,
        ISNULL(t.CostoSoporteEstimado, 0) AS CostoSoporte,
        -- Net profitability: sales minus support costs
        r.VentaNetaTotal - ISNULL(t.CostoSoporteEstimado, 0) AS RentabilidadNeta,
        -- Segmentation by recency
        CASE 
            WHEN r.DíasSinComprar <= 30 THEN 'Activo'
            WHEN r.DíasSinComprar <= 90 THEN 'En Riesgo'
            ELSE 'Inactivo'
        END AS EstadoRecencia,
        -- Segmentation by purchase frequency
        CASE 
            WHEN r.TotalÓrdenes >= 10 THEN 'Alto'
            WHEN r.TotalÓrdenes >= 5  THEN 'Medio'
            ELSE 'Bajo'
        END AS NivelFrecuencia,
        -- Segmentation by monetary value (tier)
        CASE 
            WHEN r.VentaNetaTotal >= 100000 THEN 'Premium'
            WHEN r.VentaNetaTotal >=  50000 THEN 'Gold'
            WHEN r.VentaNetaTotal >=  10000 THEN 'Silver'
            ELSE 'Bronze'
        END AS TierValor
    FROM ClienteRFM r
    LEFT JOIN ClienteTickets t ON r.CustomerID = t.CustomerID
)
-- Final query: Executive profitability report by customer
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
    -- Key metric: profitability after deducting service costs
    FORMAT(s.RentabilidadNeta, 'C0', 'es-CO') AS RentabilidadNeta
FROM Segmentacion s
-- Order by profitability to prioritize most valuable customers
ORDER BY s.RentabilidadNeta DESC;
GO
