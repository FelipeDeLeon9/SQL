# 📊 IngramBI - Business Intelligence System

Sistema completo de Business Intelligence para análisis de ventas y servicio al cliente, construido con SQL Server.

## 🎯 Descripción del Proyecto

IngramBI es un sistema de análisis de datos empresariales que integra información de ventas y tickets de soporte técnico para generar insights accionables. El proyecto incluye la estructura completa de base de datos, limpieza de datos, optimización mediante índices y más de 15 queries analíticos avanzados.

## ⚠️ Nota Importante sobre los Datos

**Los datasets utilizados en este proyecto fueron generados completamente con Inteligencia Artificial** con propósitos educativos y de demostración. Los datos NO representan información real de ninguna empresa.

## 🗂️ Estructura del Proyecto

```
SQL/
├── BI for sales and tickets/
│   ├── DATA/
│   │   ├── calendar.csv
│   │   ├── customers.csv
│   │   ├── products.csv
│   │   ├── sales_fact.csv
│   │   └── tickets.csv
│   ├── DATA CLEANING/
│   ├── EXPLORATORY DATA ANALYSIS/
│   └── Queries_for_BIsql.sql
```

## 📋 Características Principales

### 1. Arquitectura de Base de Datos
- **3 Schemas organizados**: `dim`, `fact`, `ops`
- **5 Tablas principales**:
  - `dim.Calendar` - Dimensión temporal
  - `dim.Products` - Catálogo de productos
  - `dim.Customers` - Datos de clientes
  - `fact.Sales` - Transacciones de venta
  - `ops.Tickets` - Sistema de tickets de soporte

### 2. Optimización de Performance
- Índices compuestos estratégicos
- Índices con columnas INCLUDE para evitar lookups
- Optimización de queries complejos con CTEs

### 3. Análisis Implementados

#### 📈 Análisis de Ventas
- KPIs principales del negocio
- Performance por canal de venta
- Top 10 productos estrella
- Top 5 clientes más valiosos
- Análisis por región geográfica
- Tendencias temporales (mensuales)
- Impacto de descuentos en volumen

#### 🎫 Análisis de Tickets
- Métricas de servicio al cliente
- Performance por nivel de prioridad
- Cumplimiento de SLA
- Tendencias temporales de tickets

#### 💰 Análisis Avanzados
- **Análisis Cruzado**: Correlación ventas vs. tickets por región
- **Modelo RFM**: Segmentación de clientes (Recency, Frequency, Monetary)
- **Rentabilidad Neta**: Incluye costos de soporte estimados
- **Segmentación Estratégica**: Tiers de clientes (Premium, Gold, Silver, Bronze)

## 🚀 Cómo Usar

### Requisitos Previos
- SQL Server 2016 o superior
- SQL Server Management Studio (SSMS)

### Instalación

1. **Clonar el repositorio**
```bash
git clone https://github.com/FelipeDeLeon9/SQL.git
cd SQL/BI\ for\ sales\ and\ tickets
```

2. **Crear la base de datos**
   - Abrir `Queries_for_BIsql.sql` en SSMS
   - Ejecutar la sección de creación de base de datos y schemas

3. **Importar los datos CSV**
   - Importar cada archivo CSV de la carpeta `DATA/` a sus respectivas tablas
   - Seguir el orden: Calendar → Products → Customers → Sales → Tickets

4. **Ejecutar limpieza y optimización**
   - Ejecutar las secciones de limpieza de datos
   - Crear los índices recomendados

5. **Ejecutar análisis**
   - Los queries están organizados por sección
   - Cada query está completamente documentado

## 📊 Ejemplos de Insights Generados

- 🏆 Identificación de productos más rentables
- 👥 Segmentación RFM de clientes
- 📍 Regiones con mejor/peor performance
- 🎯 Correlación entre ventas y carga de soporte
- 💵 Rentabilidad neta por cliente (ventas - costos de soporte)
- 📅 Estacionalidad en ventas y tickets

## 🛠️ Tecnologías Utilizadas

- **SQL Server** - Motor de base de datos
- **T-SQL** - Lenguaje de consultas
- **CTEs (Common Table Expressions)** - Queries complejos modulares
- **Window Functions** - Análisis avanzados
- **Índices Compuestos** - Optimización de performance

## 📝 Documentación del Código

Todo el código SQL está completamente comentado en español, incluyendo:
- Propósito de cada query
- Explicación de lógica de negocio
- Descripción de métricas calculadas
- Contexto de cada análisis

## 🎓 Propósito Educativo

Este proyecto fue desarrollado como demostración de:
- Diseño de bases de datos relacionales
- Modelado dimensional (esquema estrella)
- Optimización de queries SQL
- Análisis de datos empresariales
- Generación de insights de negocio

## 👤 Autor

**Felipe De León**
- GitHub: [@FelipeDeLeon9](https://github.com/FelipeDeLeon9)

## 📄 Licencia

Este proyecto es de código abierto y está disponible para propósitos educativos.

---

⚡ **Nota**: Los datasets fueron generados con IA y no representan datos reales de ninguna organización.
