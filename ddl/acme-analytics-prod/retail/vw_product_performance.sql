-- Source: retail.vw_product_performance (09-analytics-views.hql)
-- Green path: standard RANK/DENSE_RANK window functions — no translations needed
-- Table refs fully qualified to acme-analytics-prod.retail.*
CREATE OR REPLACE VIEW `acme-analytics-prod.retail.vw_product_performance` AS
WITH sold AS (
  SELECT
    p.product_sk,
    p.stock_code,
    p.description,
    f.country,
    SUM(f.line_total)                AS revenue,
    SUM(f.quantity)                  AS units,
    COUNT(DISTINCT f.invoice_no)     AS orders
  FROM `acme-analytics-prod.retail.dim_product` p
  JOIN `acme-analytics-prod.retail.fact_sales` f ON f.product_sk = p.product_sk
  GROUP BY p.product_sk, p.stock_code, p.description, f.country
),
ranked AS (
  SELECT
    s.*,
    RANK()       OVER (PARTITION BY s.country ORDER BY s.revenue DESC)  AS country_rank,
    DENSE_RANK() OVER (                       ORDER BY s.revenue DESC)  AS global_rank
  FROM sold s
)
SELECT * FROM ranked;
