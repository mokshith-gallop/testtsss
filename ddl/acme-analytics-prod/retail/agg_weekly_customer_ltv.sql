-- Source: retail.agg_weekly_customer_ltv (12-aggregates-rollups.hql)
-- Storage: Parquet → managed BQ table
-- Partition: PARTITIONED BY (week_start_date DATE) → PARTITION BY week_start_date
-- Type mappings applied:
--   BIGINT customer_sk → INT64
--   DECIMAL(16,2) ltv_to_date → NUMERIC(16,2)
--   INT orders_to_date, days_since_last_order → INT64
--   DECIMAL(12,2) avg_order_value → NUMERIC(12,2)
--   DECIMAL(4,3) churn_risk → NUMERIC(4,3)
CREATE TABLE `acme-analytics-prod.retail.agg_weekly_customer_ltv` (
  customer_sk         INT64,
  ltv_to_date         NUMERIC(16,2),
  orders_to_date      INT64,
  avg_order_value     NUMERIC(12,2),
  days_since_last_order INT64,
  rfm_score           STRING,
  churn_risk          NUMERIC(4,3),
  week_start_date     DATE
)
PARTITION BY week_start_date;
