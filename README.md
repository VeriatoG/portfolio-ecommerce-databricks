# E-commerce Data Analytics

End-to-end analytics project using Databricks to explore e-commerce sales, customer behavior, product performance, and competitor pricing.

The project follows a Medallion Architecture and combines data transformation, SQL and Python analysis, business intelligence dashboards, and AI-powered analytics.

> **Language note:** The documentation is in English. The dataset, table names, column names, and business terminology are in Portuguese, reflecting the original data context.

## Project Highlights

- Data ingestion and transformation using Bronze, Silver, and Gold layers.
- SQL and Python analysis of sales, customers, and products.
- Commercial and management dashboards with business KPIs.
- Databricks Genie agent for AI-powered analytics.

## Data Workflow

1. **Bronze — Data Ingestion:** Load and organize the original source data.
2. **Silver — Data Preparation:** Clean, transform, and validate the data.
3. **Gold — Analytical Data:** Prepare business-ready datasets for analysis and reporting.
4. **Analysis:** Explore business questions using SQL and Python.
5. **Business Intelligence:** Present KPIs and trends through Databricks dashboards.

## Dashboards

### Commercial Sales Dashboard

Provides a commercial view of sales performance, including:

- Total revenue, sales volume, customer count, and average ticket.
- Revenue by product category, sales channel, state, and time.
- Top-performing products by revenue.

### Sales Management Dashboard

Provides a management-level view of business performance, including:

- Total revenue, average ticket, sales volume, and active customers.
- Revenue trends and breakdowns by channel, category, and state.
- Comparison between our prices and competitor prices.
- Product-level revenue and quantity.

Both dashboards include filters to explore the data across periods, categories, and states.

## Business Questions

- How does sales performance change over time?
- Which products and categories generate the most revenue?
- How does revenue vary by sales channel and state?
- What customer purchasing patterns can be identified?
- How do our prices compare with competitor prices?
- Which KPIs can support commercial and management decisions?

## Data Sources

The project uses e-commerce data related to:

- Sales
- Products
- Customers
- Competitor prices

The datasets are processed through the Bronze, Silver, and Gold layers before being used for analysis and dashboards.

## Technologies

Databricks · SQL · Python · PySpark · Databricks Genie

## Repository Structure

The repository contains notebooks for data ingestion, transformation, SQL and Python analysis, and dashboard development.

## Databricks Genie Agent

An AI-powered analytics agent was created in the Databricks workspace. Its configuration is not currently included in this GitHub repository.

## Project Access

The dashboards are hosted in Databricks and may require workspace access:

- [Commercial Sales Dashboard](https://dbc-7f9e15f9-4844.cloud.databricks.com/dashboardsv3/01f1b86b74561f31b2db21114d95c1d5/published?o=7474644802236927)
- [Sales Management Dashboard](https://dbc-7f9e15f9-4844.cloud.databricks.com/dashboardsv3/01f1bb542faa1f77a6cdac3f773f8cb1/published?o=7474644802236927)
