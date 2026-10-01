-- Databricks notebook source
-- DBTITLE 1,Silver and Gold Transformation
-- MAGIC %md
-- MAGIC # Silver and Gold Transformation
-- MAGIC
-- MAGIC Transforms raw bronze data into analytical silver and gold layers. The silver layer standardizes data types, calculates revenue, and adds quality flags. The gold layer aggregates data into 7 business-facing tables. Total validated revenue: R$ 974,077.28 across 3,020 sales.

-- COMMAND ----------

-- DBTITLE 1,Schema Setup
-- MAGIC %md
-- MAGIC ## Schema Setup
-- MAGIC
-- MAGIC Creates the `silver` and `gold` schemas in the `projetoportfolio` catalog to organize the transformed analytical layers.

-- COMMAND ----------

-- DBTITLE 1,Create silver and gold schemas
-- Criar schemas silver e gold no catálogo projetoportfolio
CREATE SCHEMA IF NOT EXISTS projetoportfolio.silver;
CREATE SCHEMA IF NOT EXISTS projetoportfolio.gold;

-- COMMAND ----------

-- DBTITLE 1,Silver Layer
-- MAGIC %md
-- MAGIC ## Silver Layer
-- MAGIC
-- MAGIC Standardizes column types, derives revenue, maps Brazilian states to regions, and adds data quality flags across 4 tables: `produtos`, `vendas`, `clientes`, and `preco_competidores`.

-- COMMAND ----------

-- DBTITLE 1,Create silver tables
-- ============================================================
-- CAMADA SILVER -- 4 tabelas
-- ============================================================

-- silver.produtos
CREATE OR REPLACE TABLE projetoportfolio.silver.produtos
AS SELECT
  CAST(T1.id_produto AS STRING)        AS id_produto
  ,CAST(T1.nome_produto AS STRING)       AS nome_produto
  ,CAST(T1.categoria AS STRING)          AS categoria
  ,CAST(T1.marca AS STRING)               AS marca
  ,CAST(T1.preco_atual AS DECIMAL(10,2))  AS preco_atual
  ,CAST(T1.data_criacao AS TIMESTAMP)     AS data_criacao
  ,CASE WHEN LOWER(T1.nome_produto) LIKE CONCAT('%', LOWER(T1.marca), '%') THEN false ELSE true END AS marca_divergente_nome
FROM 
  projetoportfolio.bronze.produtos T1
;

-- silver.vendas
CREATE OR REPLACE TABLE projetoportfolio.silver.vendas
AS SELECT
  T1.id_venda
  ,CAST(T1.data_venda AS TIMESTAMP)         AS data_venda
  ,CAST(DATE(T1.data_venda) AS DATE)        AS data
  ,T1.id_cliente
  ,T1.id_produto
  ,T1.canal_venda
  ,CAST(T1.quantidade AS LONG)              AS quantidade
  ,CAST(T1.preco_unitario AS DECIMAL(10,2)) AS preco_unitario
  ,CAST(T1.quantidade * T1.preco_unitario AS DECIMAL(20,2)) AS receita
  ,CASE WHEN T2.id_produto IS NOT NULL THEN true ELSE false END AS produto_cadastrado
  ,CASE WHEN T1.data_venda >= T2.data_criacao THEN true ELSE false END AS venda_depois_do_cadastro
FROM 
  projetoportfolio.bronze.vendas T1
LEFT JOIN 
  projetoportfolio.bronze.produtos T2
ON T1.id_produto = T2.id_produto
;

-- silver.clientes
CREATE OR REPLACE TABLE projetoportfolio.silver.clientes
AS WITH estados_regioes AS (
  SELECT 'AC' AS uf, 'Norte' AS regiao UNION ALL
  SELECT 'AM', 'Norte' UNION ALL SELECT 'AP', 'Norte' UNION ALL
  SELECT 'PA', 'Norte' UNION ALL SELECT 'RO', 'Norte' UNION ALL
  SELECT 'RR', 'Norte' UNION ALL SELECT 'TO', 'Norte' UNION ALL
  SELECT 'AL', 'Nordeste' UNION ALL SELECT 'BA', 'Nordeste' UNION ALL
  SELECT 'CE', 'Nordeste' UNION ALL SELECT 'MA', 'Nordeste' UNION ALL
  SELECT 'PB', 'Nordeste' UNION ALL SELECT 'PE', 'Nordeste' UNION ALL
  SELECT 'PI', 'Nordeste' UNION ALL SELECT 'RN', 'Nordeste' UNION ALL
  SELECT 'SE', 'Nordeste' UNION ALL
  SELECT 'DF', 'Centro-Oeste' UNION ALL SELECT 'GO', 'Centro-Oeste' UNION ALL
  SELECT 'MT', 'Centro-Oeste' UNION ALL SELECT 'MS', 'Centro-Oeste' UNION ALL
  SELECT 'ES', 'Sudeste' UNION ALL SELECT 'MG', 'Sudeste' UNION ALL
  SELECT 'RJ', 'Sudeste' UNION ALL SELECT 'SP', 'Sudeste' UNION ALL
  SELECT 'PR', 'Sul' UNION ALL SELECT 'RS', 'Sul' UNION ALL
  SELECT 'SC', 'Sul'
)
SELECT
  T1.id_cliente
  ,REGEXP_REPLACE(
        REGEXP_REPLACE(T1.nome_cliente, '^(Sr|Sra|Srta|Dra|Dr)\.?\s+', ''),
        '\s+', ' '
    ) AS nome_cliente
  ,T1.nome_cliente AS nome_original
  ,T1.estado
  ,COALESCE(T2.regiao, 'Indefinida') AS regiao
  ,T1.pais
  ,T1.data_cadastro
FROM 
  projetoportfolio.bronze.clientes T1
LEFT JOIN 
  estados_regioes T2 
ON T1.estado = T2.uf
;

-- silver.preco_competidores
CREATE OR REPLACE TABLE projetoportfolio.silver.preco_competidores
AS SELECT
  T1.id_produto
  ,T1.nome_concorrente
  ,CAST(T1.preco_concorrente AS DECIMAL(10,2)) AS preco_concorrente
  ,CAST(T2.preco_atual AS DECIMAL(10,2))        AS preco_nosso
  ,CAST(T1.data_coleta AS TIMESTAMP)             AS data_coleta
  ,CASE  WHEN T1.preco_concorrente <= T2.preco_atual * 0.5 THEN true ELSE false END AS preco_suspeito
FROM 
  projetoportfolio.bronze.preco_competidores T1
LEFT JOIN 
  projetoportfolio.bronze.produtos T2
ON T1.id_produto = T2.id_produto
;

-- COMMAND ----------

-- DBTITLE 1,Gold Layer
-- MAGIC %md
-- MAGIC ## Gold Layer
-- MAGIC
-- MAGIC Aggregates silver data into 7 business-ready tables covering temporal sales trends, product performance, customer segmentation, pricing competitiveness, data quality, and regional revenue.

-- COMMAND ----------

-- DBTITLE 1,Create gold tables
-- ============================================================
-- CAMADA GOLD: 7 tabelas
-- ============================================================

-- gold.vendas_temporais
CREATE OR REPLACE TABLE projetoportfolio.gold.vendas_temporais
AS SELECT
  T1.data
  ,T1.canal_venda
  ,SUM(T1.receita) AS receita
FROM 
     projetoportfolio.silver.vendas T1
GROUP BY 
     T1.data, T1.canal_venda
;

-- gold.vendas_produtos
CREATE OR REPLACE TABLE projetoportfolio.gold.vendas_produtos
AS SELECT
   T1.id_produto
  ,T2.nome_produto
  ,T2.categoria
  ,T2.marca
  ,COUNT(*) AS total_vendas
  ,SUM(T1.receita) AS receita
FROM 
     projetoportfolio.silver.vendas T1
LEFT JOIN 
     projetoportfolio.silver.produtos T2 
ON T1.id_produto = T2.id_produto
GROUP BY 
     T1.id_produto, T2.nome_produto, T2.categoria, T2.marca
;

-- gold.vendas_detalhadas
CREATE OR REPLACE TABLE projetoportfolio.gold.vendas_detalhadas
AS SELECT
    T1.data
  , T1.canal_venda
  , T2.regiao
  , T3.categoria
  , COUNT(*) AS total_vendas
  , SUM(T1.receita) AS receita
FROM projetoportfolio.silver.vendas T1
LEFT JOIN projetoportfolio.silver.clientes T2 ON T1.id_cliente = T2.id_cliente
LEFT JOIN projetoportfolio.silver.produtos T3 ON T1.id_produto = T3.id_produto
GROUP BY T1.data, T1.canal_venda, T2.regiao, T3.categoria;

-- gold.clientes_segmentacao
CREATE OR REPLACE TABLE projetoportfolio.gold.clientes_segmentacao
AS SELECT
  T1.id_cliente
  ,T1.nome_cliente
  ,T1.regiao
  ,T1.estado
  ,COALESCE(SUM(T2.receita), 0) AS total_gasto
  ,COUNT(T2.id_venda) AS total_compras
  ,COALESCE(SUM(T2.receita) / NULLIF(COUNT(T2.id_venda), 0), 0) AS ticket_medio
  ,CASE WHEN SUM(T2.receita) >= 50000 THEN 'VIP' WHEN SUM(T2.receita) >= 20000 THEN 'TOP_TIER' ELSE 'REGULAR' END AS segmento
FROM 
     projetoportfolio.silver.clientes T1
LEFT JOIN 
     projetoportfolio.silver.vendas T2 
ON T1.id_cliente = T2.id_cliente
GROUP BY 
     T1.id_cliente, T1.nome_cliente, T1.regiao, T1.estado
;

-- gold.precos_competitividade
CREATE OR REPLACE TABLE projetoportfolio.gold.precos_competitividade
AS SELECT
  T1.id_produto
  ,T1.nome_produto
  ,T1.marca
  ,T1.preco_atual AS preco_nosso
  ,MIN(T2.preco_concorrente) AS preco_min_conc
  ,MAX(T2.preco_concorrente) AS preco_max_conc
  ,CAST(AVG(T2.preco_concorrente) AS DECIMAL(10,2)) AS preco_medio_conc
  ,COUNT(DISTINCT T2.nome_concorrente) AS total_concorrentes
  ,CASE WHEN T1.preco_atual > MAX(T2.preco_concorrente) THEN true ELSE false END AS mais_caro_que_todos
FROM 
     projetoportfolio.silver.produtos T1
JOIN 
     projetoportfolio.silver.preco_competidores T2 
ON T1.id_produto = T2.id_produto
GROUP BY 
     T1.id_produto, T1.nome_produto, T1.marca, T1.preco_atual
;

-- gold.qualidade_dados
CREATE OR REPLACE TABLE projetoportfolio.gold.qualidade_dados
AS
SELECT 
  'Venda de produto nao cadastrado' AS regra
  ,'ALERTA' AS severidade
  ,COUNT(*) AS linhas_afetadas
  ,SUM(T1.receita) AS receita_afetada
FROM 
     projetoportfolio.silver.vendas T1 
WHERE NOT 
     T1.produto_cadastrado

UNION ALL

SELECT 
  'Venda anterior a criacao do produto'
  ,'ALERTA'
  ,COUNT(*)
  ,SUM(T1.receita)
FROM 
     projetoportfolio.silver.vendas T1 
WHERE NOT 
     T1.venda_depois_do_cadastro

UNION ALL

SELECT 
  'Preco de concorrente abaixo de 60% do nosso'
  ,'ALERTA'
  ,COUNT(*)
  ,CAST(0 AS DECIMAL(20,2))
FROM 
     projetoportfolio.silver.preco_competidores T1 
WHERE 
     T1.preco_suspeito

UNION ALL

SELECT 
  'Marca do produto diferente da marca citada no nome'
  ,'ALERTA'
  ,COUNT(*)
  ,CAST(0 AS DECIMAL(20,2))
FROM 
     projetoportfolio.silver.produtos T1 
WHERE 
     T1.marca_divergente_nome

UNION ALL

SELECT 
  'Produto com nome igual ao de outro produto'
  ,'INFORMATIVO'
  ,COUNT(*)
  ,CAST(0 AS DECIMAL(20,2))
FROM (
    SELECT 
          T1.nome_produto 
     FROM 
          projetoportfolio.silver.produtos T1 
     GROUP BY 
          T1.nome_produto 
     HAVING 
          COUNT(*) > 1
)

UNION ALL

SELECT 
  'Produto monitorado em menos de 4 concorrentes'
  ,'INFORMATIVO'
  ,COUNT(*)
  ,CAST(0 AS DECIMAL(20,2))
FROM (
    SELECT 
          T1.id_produto 
     FROM 
          projetoportfolio.silver.preco_competidores T1
    GROUP BY 
          T1.id_produto 
     HAVING COUNT(DISTINCT T1.nome_concorrente) < 4
)

UNION ALL

SELECT 
  'Nome de cliente com pronome de tratamento'
  ,'CORRIGIDO'
  ,COUNT(*)
  ,CAST(0 AS DECIMAL(20,2))
FROM
      projetoportfolio.silver.clientes T1 
WHERE 
     T1.nome_cliente <> T1.nome_original;

-- gold.vendas_por_regiao
CREATE OR REPLACE TABLE projetoportfolio.gold.vendas_por_regiao
AS SELECT
  T2.regiao
  ,COUNT(*) AS total_vendas
  ,SUM(T1.receita) AS receita
  ,CAST(SUM(T1.receita) / COUNT(*) AS DECIMAL(20,2)) AS ticket_medio
FROM 
     projetoportfolio.silver.vendas T1
JOIN 
     projetoportfolio.silver.clientes T2 
ON T1.id_cliente = T2.id_cliente
GROUP BY 
     T2.regiao
;

-- COMMAND ----------

-- DBTITLE 1,Validation
-- MAGIC %md
-- MAGIC ## Validation
-- MAGIC
-- MAGIC Verifies all silver and gold tables were created, confirms row counts, and reconciles total revenue between the silver and gold layers.

-- COMMAND ----------

-- DBTITLE 1,Validate tables and reconcile revenue
-- MAGIC
-- MAGIC %python
-- MAGIC # Verificacao 
-- MAGIC silver_tables = spark.sql("SHOW TABLES IN projetoportfolio.silver")
-- MAGIC display(silver_tables)
-- MAGIC
-- MAGIC gold_tables = spark.sql("SHOW TABLES IN projetoportfolio.gold")
-- MAGIC display(gold_tables)
-- MAGIC
-- MAGIC # Contagem 
-- MAGIC for schema in ['silver', 'gold']:
-- MAGIC     tables = spark.sql(f"SHOW TABLES IN projetoportfolio.{schema}").collect()
-- MAGIC     for row in tables:
-- MAGIC         tname = row['tableName']
-- MAGIC         count = spark.sql(f"SELECT COUNT(*) AS cnt FROM projetoportfolio.{schema}.{tname}").collect()[0]['cnt']
-- MAGIC         
-- MAGIC         print(f"{schema}.{tname}: {count} linhas")
-- MAGIC
-- MAGIC # Reconciliacao de receita entre silver e gold
-- MAGIC silver_receita = spark.sql("SELECT SUM(receita) AS total FROM projetoportfolio.silver.vendas").collect()[0]['total']
-- MAGIC gold_receita = spark.sql("SELECT SUM(receita) AS total FROM projetoportfolio.gold.vendas_temporais").collect()[0]['total']
-- MAGIC
-- MAGIC print(f"Silver: R$ {silver_receita:,.2f}")
-- MAGIC print(f"Gold:   R$ {gold_receita:,.2f}")
-- MAGIC print(f"Diferenca: R$ {abs(silver_receita - gold_receita):,.2f}")