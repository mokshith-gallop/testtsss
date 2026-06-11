-- Source: retail.vw_daily_sales_by_country (09-analytics-views.hql)
-- Green path: standard CTE + GROUP BY + COALESCE — no function translations needed
-- Table refs fully qualified to acme-analytics-prod.retail.*
CREATE OR REPLACE VIEW `acme-analytics-prod.retail.vw_daily_sales_by_country` AS
WITH daily AS (
  SELECT
    sale_date,
    country,
    COUNT(DISTINCT invoice_no)                  AS orders,
    SUM(line_total)                             AS revenue,
    SUM(quantity)                               AS units,
    COUNT(DISTINCT customer_sk)                 AS active_customers
  FROM `acme-analytics-prod.retail.fact_sales`
  GROUP BY sale_date, country
)
SELECT
  d.sale_date,
  d.country,
  d.orders,
  d.revenue,
  d.units,
  d.active_customers,
  COALESCE(d.revenue / NULLIF(d.orders, 0), 0)  AS aov,
  COALESCE(d.units  / NULLIF(d.orders, 0), 0)   AS basket_size
FROM daily d;
