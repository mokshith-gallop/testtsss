-- Source: retail.agg_monthly_supplier_performance (12-aggregates-rollups.hql)
-- Storage: Parquet → managed BQ table
-- Partition: PARTITIONED BY (month_start DATE) → PARTITION BY month_start
-- Type mappings applied:
--   BIGINT supplier_sk, units_received → INT64
--   INT orders_placed → INT64
--   DECIMAL(5,4) on_time_pct, fill_rate_pct → NUMERIC(5,4)
--   DECIMAL(6,2) avg_lead_time_days → NUMERIC(6,2)
--   DECIMAL(4,3) quality_score → NUMERIC(4,3)
--   DECIMAL(16,2) total_spend → NUMERIC(16,2)
CREATE TABLE `acme-analytics-prod.retail.agg_monthly_supplier_performance` (
  supplier_sk        INT64,
  orders_placed      INT64,
  units_received     INT64,
  on_time_pct        NUMERIC(5,4),
  fill_rate_pct      NUMERIC(5,4),
  avg_lead_time_days NUMERIC(6,2),
  quality_score      NUMERIC(4,3),
  total_spend        NUMERIC(16,2),
  month_start        DATE
)
PARTITION BY month_start;
