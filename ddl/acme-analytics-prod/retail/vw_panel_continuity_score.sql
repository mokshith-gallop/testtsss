-- Source: retail.vw_panel_continuity_score (16-additional-views.hql)
-- Function translations applied:
--   T4: normalize_country(x) → normalize_country_js(x) (BQ JS UDF)
--        UDF used inside JOIN ON clause
--   date_sub(current_date(), 90) → DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
-- Prerequisite: normalize_country_js UDF must be created before this view
-- Table refs fully qualified to acme-analytics-prod.retail.*
CREATE OR REPLACE VIEW `acme-analytics-prod.retail.vw_panel_continuity_score` AS
SELECT
    f.customer_sk,
    COUNT(DISTINCT f.sale_date)         AS active_days,
    COUNT(DISTINCT f.product_sk)        AS distinct_products,
    SUM(f.line_total)                   AS total_spend
FROM `acme-analytics-prod.retail.fact_sales` f
JOIN `acme-analytics-prod.retail.dim_customer` c
  ON c.customer_sk = f.customer_sk
 AND normalize_country_js(c.country) = normalize_country_js(f.country)
WHERE f.sale_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
GROUP BY f.customer_sk;
