-- Source: retail.vw_customer_lifetime_value (09-analytics-views.hql)
-- Function translations applied:
--   R8: DATEDIFF(a, b) → DATE_DIFF(a, b, DAY)
-- Table refs fully qualified to acme-analytics-prod.retail.*
CREATE OR REPLACE VIEW `acme-analytics-prod.retail.vw_customer_lifetime_value` AS
WITH per_customer AS (
  SELECT
    c.customer_sk,
    c.customer_id,
    c.country,
    MIN(f.sale_date)              AS first_order_date,
    MAX(f.sale_date)              AS last_order_date,
    COUNT(DISTINCT f.invoice_no)  AS orders,
    SUM(f.line_total)             AS lifetime_revenue
  FROM `acme-analytics-prod.retail.dim_customer` c
  LEFT JOIN `acme-analytics-prod.retail.fact_sales` f ON f.customer_sk = c.customer_sk
  GROUP BY c.customer_sk, c.customer_id, c.country
)
SELECT
  customer_sk,
  customer_id,
  country,
  first_order_date,
  last_order_date,
  orders,
  lifetime_revenue,
  DATE_DIFF(CURRENT_DATE(), last_order_date, DAY)  AS recency_days,
  CASE
    WHEN orders = 0                                              THEN 'never'
    WHEN DATE_DIFF(CURRENT_DATE(), last_order_date, DAY) <= 30   THEN 'active'
    WHEN DATE_DIFF(CURRENT_DATE(), last_order_date, DAY) <= 90   THEN 'warm'
    WHEN DATE_DIFF(CURRENT_DATE(), last_order_date, DAY) <= 365  THEN 'cold'
    ELSE 'churned'
  END                                                AS rfm_bucket
FROM per_customer;
