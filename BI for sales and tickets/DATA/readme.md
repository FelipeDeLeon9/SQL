📊 Business Intelligence System for Sales and Tickets

A complete Business Intelligence system for sales and customer service analysis, built with SQL Server.

🎯 Project Description

This is a business data analysis system that integrates sales and technical support ticket information to generate actionable insights. The project includes a full database structure, data cleaning, performance optimization through indexes, and more than 15 advanced analytical queries.

⚠️ Important Note About the Data

The datasets used in this project were entirely generated with Artificial Intelligence for educational and demonstration purposes. The data does NOT represent real information from any company.

🗂️ Project Structure
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

📋 Main Features
1. Database Architecture

3 organized schemas: dim, fact, ops

5 main tables:

dim.Calendar - Time dimension

dim.Products - Product catalog

dim.Customers - Customer data

fact.Sales - Sales transactions

ops.Tickets - Support ticket system

2. Performance Optimization

Strategic composite indexes

Indexes with INCLUDE columns to avoid lookups

Optimization of complex queries using CTEs

3. Implemented Analyses
📈 Sales Analysis

Key business KPIs

Performance by sales channel

Top 10 best-selling products

Top 5 most valuable customers

Analysis by geographic region

Temporal trends (monthly)

Impact of discounts on volume

🎫 Ticket Analysis

Customer service metrics

Performance by priority level

SLA compliance

Ticket time trends

💰 Advanced Analyses

Cross Analysis: Correlation between sales and tickets by region

RFM Model: Customer segmentation (Recency, Frequency, Monetary)

Net Profitability: Includes estimated support costs

Strategic Segmentation: Customer tiers (Premium, Gold, Silver, Bronze)

🚀 How to Use
Prerequisites

SQL Server 2016 or later

SQL Server Management Studio (SSMS)

Installation

Clone the repository

git clone https://github.com/FelipeDeLeon9/SQL.git
cd SQL/BI\ for\ sales\ and\ tickets


Create the database

Open Queries_for_BIsql.sql in SSMS

Run the database and schema creation sections

Import the CSV data

Import each CSV file from the DATA/ folder into its respective table

Follow this order: Calendar → Products → Customers → Sales → Tickets

Run cleaning and optimization

Execute the data cleaning sections

Create the recommended indexes

Run analyses

Queries are organized by section

Each query is fully documented

📊 Sample Insights Generated

🏆 Identification of the most profitable products

👥 RFM-based customer segmentation

📍 Regions with best/worst performance

🎯 Correlation between sales and support workload

💵 Net profitability per customer (sales - support costs)

📅 Seasonality in sales and tickets

🛠️ Technologies Used

SQL Server – Database engine

T-SQL – Query language

CTEs (Common Table Expressions) – Modular complex queries

Window Functions – Advanced analytics

Composite Indexes – Performance optimization

📝 Code Documentation

All SQL code is fully commented in Spanish, including:

Purpose of each query

Business logic explanation

Description of calculated metrics

Context for each analysis

🎓 Educational Purpose

This project was developed as a demonstration of:

Relational database design

Dimensional modeling (star schema)

SQL query optimization

Business data analysis

Generation of business insights

👤 Author

Felipe De León

GitHub: @FelipeDeLeon9

📄 License

This project is open-source and available for educational purposes.

⚡ Note: The datasets were generated with AI and do not represent real data from any organization.
