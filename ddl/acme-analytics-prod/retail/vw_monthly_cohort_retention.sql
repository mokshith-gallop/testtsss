-- Source: retail.vw_monthly_cohort_retention (09-analytics-views.hql)
-- Function translations applied:
--   R8: DATE_FORMAT(d, 'yyyy-MM') → FORMAT_DATE('%Y-%m', d)
--   R8: MONTHS_BETWEEN(a, b) → DATE_DIFF(a, b, MONTH)
--   R8: to_date(concat(s, '-01')) → PARSE_DATE('%Y-%m-%d', CONCAT(s, '-01'))
--   CAST(... AS INT) → CAST(... AS INT64)
-- Table refs fully qualified to acme-analytics-prod.retail.*
CREATE OR REPLACE VIEW `acme-analytics-prod.retail.vw_monthly_cohort_retention` AS
WITH first_order AS (
  SELECT
    customer_sk,
    FORMAT_DATE('%Y-%m', MIN(sale_date)) AS cohort_month
  FROM `acme-analytics-prod.retail.fact_sales`
  GROUP BY customer_sk
),
orders AS (
  SELECT
    f.customer_sk,
    fo.cohort_month,
    FORMAT_DATE('%Y-%m', f.sale_date)                                                  AS order_month,
    DATE_DIFF(f.sale_date, PARSE_DATE('%Y-%m-%d', CONCAT(fo.cohort_month, '-01')), MONTH) AS months_since_first
  FROM `acme-analytics-prod.retail.fact_sales` f
  JOIN first_order fo ON fo.customer_sk = f.customer_sk
)
SELECT
  cohort_month,
  CAST(months_since_first AS INT64)    AS months_since_first,
  COUNT(DISTINCT customer_sk)          AS active_customers
FROM orders
GROUP BY cohort_month, CAST(months_since_first AS INT64);
