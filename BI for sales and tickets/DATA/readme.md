# 📊 RetailBI - Business Intelligence System

Complete Business Intelligence system for sales and customer service analysis, built with SQL Server.

## 🎯 Project Description

RetailBI is a business data analysis system that integrates sales information and technical support tickets to generate actionable insights. The project includes the complete database structure, data cleaning, optimization through indexes, and more than 15 advanced analytical queries.

## ⚠️ Important Note About the Data

**The datasets used in this project were completely generated with Artificial Intelligence** for educational and demonstration purposes. The data does NOT represent real information from any company.

## 🗂️ Project Structure

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

## 📋 Key Features

### 1. Database Architecture
- **3 Organized Schemas**: `dim`, `fact`, `ops`
- **5 Main Tables**:
  - `dim.Calendar` - Time dimension
  - `dim.Products` - Product catalog
  - `dim.Customers` - Customer data
  - `fact.Sales` - Sales transactions
  - `ops.Tickets` - Support ticket system

### 2. Performance Optimization
- Strategic composite indexes
- Indexes with INCLUDE columns to avoid lookups
- Complex query optimization with CTEs

### 3. Implemented Analytics

#### 📈 Sales Analysis
- Main business KPIs
- Performance by sales channel
- Top 10 star products
- Top 5 most valuable customers
- Analysis by geographic region
- Time trends (monthly)
- Discount impact on volume

#### 🎫 Ticket Analysis
- Customer service metrics
- Performance by priority level
- SLA compliance
- Ticket time trends

#### 💰 Advanced Analytics
- **Cross Analysis**: Sales vs. tickets correlation by region
- **RFM Model**: Customer segmentation (Recency, Frequency, Monetary)
- **Net Profitability**: Includes estimated support costs
- **Strategic Segmentation**: Customer tiers (Premium, Gold, Silver, Bronze)

## 🚀 How to Use

### Prerequisites
- SQL Server 2016 or higher
- SQL Server Management Studio (SSMS)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/FelipeDeLeon9/SQL.git
cd SQL/BI\ for\ sales\ and\ tickets
```

2. **Create the database**
   - Open `Queries_for_BIsql.sql` in SSMS
   - Execute the database and schema creation section

3. **Import CSV data**
   - Import each CSV file from the `DATA/` folder to their respective tables
   - Follow the order: Calendar → Products → Customers → Sales → Tickets

4. **Run cleaning and optimization**
   - Execute the data cleaning sections
   - Create the recommended indexes

5. **Run analytics**
   - Queries are organized by section
   - Each query is fully documented

## 📊 Examples of Generated Insights

- 🏆 Identification of most profitable products
- 👥 RFM customer segmentation
- 📍 Regions with best/worst performance
- 🎯 Correlation between sales and support load
- 💵 Net profitability by customer (sales - support costs)
- 📅 Seasonality in sales and tickets

## 🛠️ Technologies Used

- **SQL Server** - Database engine
- **T-SQL** - Query language
- **CTEs (Common Table Expressions)** - Modular complex queries
- **Window Functions** - Advanced analytics
- **Composite Indexes** - Performance optimization

## 📝 Code Documentation

All SQL code is fully commented in Spanish, including:
- Purpose of each query
- Business logic explanation
- Description of calculated metrics
- Context of each analysis

## 🎓 Educational Purpose

This project was developed as a demonstration of:
- Relational database design
- Dimensional modeling (star schema)
- SQL query optimization
- Business data analysis
- Business insight generation

## 👤 Author

**Felipe De León**
- GitHub: [@FelipeDeLeon9](https://github.com/FelipeDeLeon9)

## 📄 License

This project is open source and available for educational purposes.

---

⚡ **Note**: The datasets were generated with AI and do not represent real data from any organization.
