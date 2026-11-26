# E-commerce Data Analytics

End-to-end analytics project using Databricks to explore e-commerce sales, customer behavior, product performance, and competitor pricing.

The project uses a Medallion Architecture to transform source data into business-ready datasets, analyze performance with SQL and Python, and present insights through Databricks dashboards.

> **Language note:** The documentation is in English. The dataset, table names, column names, and business terminology are in Portuguese, reflecting the original data context.

## Data Workflow

1. **Bronze — Data Ingestion:** Load and organize the original source data.
2. **Silver — Data Preparation:** Clean, transform, and validate the data.
3. **Gold — Analytical Data:** Prepare business-ready datasets for analysis and reporting.
4. **Analysis:** Explore sales, customer, and product data using SQL and Python.
5. **Business Intelligence:** Present KPIs and trends through Databricks dashboards.

## Dashboards

### Commercial Sales Dashboard

Provides a commercial view of sales performance, including:
- Revenue, sales volume, customer count, and average ticket.
- Revenue by product category, sales channel, state, and time.
- Top-performing products by revenue.

### Sales Management Dashboard

Provides a management-level view of business performance, including:
- Revenue, average ticket, sales volume, and active customers.
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

## Technologies

Databricks · SQL · Python · PySpark · Databricks Genie

## Databricks Genie Agent

An AI-powered analytics agent was created in the Databricks workspace. Its configuration is not currently included in this GitHub repository.

## Project Access

The dashboards are hosted in Databricks and may require workspace access:

- [Commercial Sales Dashboard](https://dbc-7f9e15f9-4844.cloud.databricks.com/dashboardsv3/01f1b86b74561f31b2db21114d95c1d5/published?o=7474644802236927)
- [Sales Management Dashboard](https://dbc-7f9e15f9-4844.cloud.databricks.com/dashboardsv3/01f1bb542faa1f77a6cdac3f773f8cb1/published?o=7474644802236927)
