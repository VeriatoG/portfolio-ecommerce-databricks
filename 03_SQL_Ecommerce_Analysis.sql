-- Databricks notebook source
-- DBTITLE 1,Seção 1: Conhecendo os Dados
-- MAGIC %md
-- MAGIC ---
-- MAGIC
-- MAGIC ## Getting to Know the Data
-- MAGIC
-- MAGIC Before performing complex analyses, let's explore the structure and content of each table.

-- COMMAND ----------

-- DBTITLE 1,1.1 tabela Vendas
-- View the first 10 sales
-- Initial exploration: data types, values, patterns

SELECT 
    *
FROM 
    projetoportfolio.bronze.vendas
ORDER BY 
    2 DESC
LIMIT 
    10
;

-- COMMAND ----------

-- DBTITLE 1,1.2 tabela Produtos
-- Product catalog with categories and brands

SELECT 
    *
FROM 
    projetoportfolio.bronze.produtos
ORDER BY 
    3, 2
LIMIT 
    10
;

-- COMMAND ----------

-- DBTITLE 1,1.3 tabela Clientes
-- Customer base by state

SELECT 
    *
FROM 
    projetoportfolio.bronze.clientes
ORDER BY 
    3
LIMIT 
    10
;

-- COMMAND ----------

-- DBTITLE 1,1.4 Vendas do E-commerce com quantidade
-- WHERE example: Online sales with significant quantity

SELECT 
  id_venda
  ,data_venda
  ,canal_venda
  ,quantidade
  ,preco_unitario
  ,(quantidade * preco_unitario) AS valor_total
FROM 
  projetoportfolio.bronze.vendas
WHERE 
  canal_venda = 'ecommerce' AND quantidade >= 3
ORDER BY 
  4 DESC
LIMIT 
  15
;

-- COMMAND ----------

-- DBTITLE 1,Seção 2: Diretoria de Vendas
-- MAGIC %md
-- MAGIC ---
-- MAGIC
-- MAGIC ## Sales Management
-- MAGIC
-- MAGIC Strategic analyses for the commercial team: revenue, average ticket, performance by channel and category.

-- COMMAND ----------

-- DBTITLE 1,2.1 KPIs Principais: Receita Total, Ticket Médio, N Vendas
-- Key business metrics
-- Total Revenue = sum(quantity * unit_price) and Average Ticket = revenue / number of sales

SELECT 
    SUM(quantidade * preco_unitario) AS receita_total
    ,AVG(quantidade * preco_unitario) AS ticket_medio
    ,COUNT(*) AS num_vendas
    ,SUM(quantidade) AS unidades_vendidas
FROM 
    projetoportfolio.bronze.vendas
;

-- COMMAND ----------

-- DBTITLE 1,2.2 Performance por Canal de Venda
-- E-commerce vs. Physical Store comparison
-- Which channel brings more revenue? Which has a better average ticket?

SELECT 
    canal_venda
    ,SUM(quantidade * preco_unitario) AS receita
    ,AVG(quantidade * preco_unitario) AS ticket_medio
    ,COUNT(*) AS num_vendas
    ,SUM(quantidade) AS unidades_vendidas
FROM 
    projetoportfolio.bronze.vendas
GROUP BY 
    1
ORDER BY 
    2 DESC
;

-- COMMAND ----------

-- DBTITLE 1,2.3 Receita por Categoria de Produto
-- Cross-table analysis: sales + products
-- Which category brings more revenue?

SELECT 
    t2.categoria
    ,SUM(t1.quantidade * t1.preco_unitario) AS receita
    ,COUNT(t1.id_venda) AS num_vendas
    ,AVG(t1.quantidade * t1.preco_unitario) AS ticket_medio
FROM 
    projetoportfolio.bronze.vendas AS t1
INNER JOIN 
    projetoportfolio.bronze.produtos AS t2
ON 
    t1.id_produto = t2.id_produto
GROUP BY 
    1
ORDER BY 
    2 DESC
;

-- COMMAND ----------

-- DBTITLE 1,2.4 Top 10 Produtos Mais Vendidos
-- Product ranking by revenue generated

SELECT 
    t2.nome_produto
    ,t2.categoria
    ,t2.marca
    ,SUM(t1.quantidade * t1.preco_unitario) AS receita
    ,SUM(t1.quantidade) AS unidades_vendidas
    ,COUNT(t1.id_venda) AS num_vendas
FROM 
    projetoportfolio.bronze.vendas AS t1
INNER JOIN 
    projetoportfolio.bronze.produtos AS t2
ON 
    t1.id_produto = t2.id_produto
GROUP BY 
    1, 2, 3
ORDER BY 
    4 DESC
LIMIT 
    10
;

-- COMMAND ----------

-- DBTITLE 1,2.5 Detecção de Vendas Sem Produto

-- Data Quality validation and detection of sales without registered products

SELECT 
    t1.id_venda
    ,t1.id_produto
    ,t2.nome_produto
    ,t1.quantidade
    ,t1.preco_unitario
FROM 
    projetoportfolio.bronze.vendas AS t1
LEFT JOIN 
    projetoportfolio.bronze.produtos AS t2
ON 
    t1.id_produto = t2.id_produto
WHERE 
    t2.id_produto IS NULL
LIMIT 
    20
;

-- If it returns zero, all sold products are registered

-- COMMAND ----------

-- DBTITLE 1,Seção 3: Diretoria de Clientes
-- MAGIC %md
-- MAGIC ---
-- MAGIC
-- MAGIC ## Customer Management
-- MAGIC
-- MAGIC Customer base analysis: identification of top customers and geographic revenue distribution.

-- COMMAND ----------

-- DBTITLE 1,3.1 Top 10 Clientes por Receita
-- Ranking of most valuable customers
-- Potential basis for loyalty program and retention actions

SELECT 
    t2.id_cliente
    ,t2.nome_cliente
    ,t2.estado
    ,SUM(t1.quantidade * t1.preco_unitario) AS receita_total
    ,COUNT(t1.id_venda) AS num_compras
    ,AVG(t1.quantidade * t1.preco_unitario) AS ticket_medio
FROM 
    projetoportfolio.bronze.vendas AS t1
INNER JOIN 
    projetoportfolio.bronze.clientes AS t2
ON 
    t1.id_cliente = t2.id_cliente
GROUP BY 
    t2.id_cliente, t2.nome_cliente, t2.estado
ORDER BY 
    receita_total DESC
LIMIT 
    10
;

-- COMMAND ----------

-- DBTITLE 1,3.2 Receita por Estado
-- Where are the best customers located?
-- Could this be a basis for expansion strategy and regional marketing?

SELECT 
    t2.estado
    ,SUM(t1.quantidade * t1.preco_unitario) AS receita_total
    ,COUNT(DISTINCT t2.id_cliente) AS num_clientes
    ,COUNT(t1.id_venda) AS num_vendas
    ,AVG(t1.quantidade * t1.preco_unitario) AS ticket_medio
FROM 
    projetoportfolio.bronze.vendas AS t1
INNER JOIN 
    projetoportfolio.bronze.clientes AS t2
ON 
    t1.id_cliente = t2.id_cliente
GROUP BY 
    t2.estado
ORDER BY 
    receita_total DESC
;

-- COMMAND ----------

-- DBTITLE 1,Seção 4: Diretoria de Pricing
-- MAGIC %md
-- MAGIC ---
-- MAGIC
-- MAGIC ## Pricing Management
-- MAGIC
-- MAGIC Competitive price analysis: positioning vs. competitors by category.

-- COMMAND ----------

-- DBTITLE 1,4.1 Comparação: Preço Médio Nosso vs. Concorrentes (por Categoria)
-- Price positioning analysis by category and comparison of our average price with the market

WITH nossos_precos AS (
    SELECT 
        t1.categoria
        ,AVG(t1.preco_atual) AS preco_medio_nosso
    FROM 
        projetoportfolio.bronze.produtos AS t1
    GROUP BY 
        t1.categoria
)
,precos_concorrentes AS (
    SELECT 
        t1.categoria
        ,AVG(t2.preco_concorrente) AS preco_medio_concorrente
    FROM 
        projetoportfolio.bronze.preco_competidores AS t2
    INNER JOIN 
        projetoportfolio.bronze.produtos AS t1
    ON t2.id_produto = t1.id_produto
    GROUP BY 
        t1.categoria
)
SELECT 
    t1.categoria
    ,ROUND(t1.preco_medio_nosso, 2) AS preco_medio_nosso
    ,ROUND(t2.preco_medio_concorrente, 2) AS preco_medio_concorrente
    ,ROUND(t1.preco_medio_nosso - t2.preco_medio_concorrente, 2) AS diferenca_preco
    ,ROUND(((t1.preco_medio_nosso / t2.preco_medio_concorrente) - 1) * 100, 2) AS diferenca_percentual
FROM 
    nossos_precos AS t1
INNER JOIN 
    precos_concorrentes AS t2
ON t1.categoria = t2.categoria
ORDER BY 
    diferenca_percentual DESC;

-- COMMAND ----------

-- DBTITLE 1,4.2 Produtos Mais Caros Que TODOS os Concorrentes
-- Identify products where we are priced above the market
-- Opportunity for price review or highlighting differentials

SELECT 
    t1.id_produto
    ,t1.nome_produto
    ,t1.categoria
    ,ROUND(t1.preco_atual, 2) AS nosso_preco
    ,ROUND(MAX(t2.preco_concorrente), 2) AS maior_preco_concorrente
    ,ROUND(t1.preco_atual - MAX(t2.preco_concorrente), 2) AS diferenca
    ,ROUND(((t1.preco_atual / MAX(t2.preco_concorrente)) - 1) * 100, 2) AS percentual_acima
FROM 
    projetoportfolio.bronze.produtos AS t1
INNER JOIN 
    projetoportfolio.bronze.preco_competidores AS t2
ON t1.id_produto = t2.id_produto
GROUP BY 
    t1.id_produto, t1.nome_produto, t1.categoria, t1.preco_atual
HAVING 
    t1.preco_atual > MAX(t2.preco_concorrente)
ORDER BY 
    7 DESC
LIMIT 
    15
;

-- COMMAND ----------

-- DBTITLE 1,Conclusão e Dashboard
-- MAGIC %md
-- MAGIC ---
-- MAGIC
-- MAGIC ## Conclusion
-- MAGIC
-- MAGIC Throughout this project, I explored the e-commerce data from **3,020 sales** and built analyses for three directorates. It was enriching to see how the data tells the story of the business:
-- MAGIC
-- MAGIC * **Sales**: I found a total revenue of **R$ 974K**, with an average ticket of **R$ 322.54**. E-commerce stood out as the main channel, representing **72% of revenue** — a clear sign that the digital strategy is on the right track.
-- MAGIC * **Customers**: The base consists of **50 active customers**, heavily concentrated in **SP** and **RJ**. This makes me think about how we can expand to other regions and strengthen retention of our existing customers.
-- MAGIC * **Pricing**: Competitive positioning varies significantly by category. I identified products where we are priced above the market, which opens room for strategic price reviews without losing competitiveness.
-- MAGIC
-- MAGIC Overall, I am satisfied with what I was able to extract from this data. Each directorate gained a clear and actionable view, and I feel this project effectively demonstrates the value of a well-structured data analysis.
-- MAGIC
-- MAGIC ### Interactive Dashboard
-- MAGIC
-- MAGIC [![Commercial Dashboard](https://img.shields.io/badge/Commercial_Dashboard-Open-blue?style=for-the-badge)](https://dbc-7f9e15f9-4844.cloud.databricks.com/dashboardsv3/01f1b86b74561f31b2db21114d95c1d5/published?o=7474644802236927)
-- MAGIC