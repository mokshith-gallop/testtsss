-- Source: retail.vw_sales_rollup_by_region (16-additional-views.hql)
-- Function translations applied:
--   R4: GROUP BY ... WITH ROLLUP → GROUP BY ROLLUP(s.region, s.store_sk)
--   R4: GROUPING__ID → GROUPING(s.region) * 2 + GROUPING(s.store_sk)
--   date_sub(current_date(), 7) → DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
-- Table refs fully qualified to acme-analytics-prod.retail.*
CREATE OR REPLACE VIEW `acme-analytics-prod.retail.vw_sales_rollup_by_region` AS
SELECT
    s.region,
    s.store_sk,
    SUM(f.line_total)                                        AS total_revenue,
    COUNT(*)                                                 AS line_count,
    GROUPING(s.region) * 2 + GROUPING(s.store_sk)           AS grouping_level
FROM `acme-analytics-prod.retail.fact_sales` f
JOIN `acme-analytics-prod.retail.dim_store` s ON s.store_sk = f.customer_sk
WHERE f.sale_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY ROLLUP(s.region, s.store_sk);
