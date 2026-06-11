-- Source: retail.agg_returns_by_reason_monthly (12-aggregates-rollups.hql)
-- Storage: Parquet → managed BQ table
-- Partition: PARTITIONED BY (month_start DATE) → PARTITION BY month_start
-- Type mappings applied:
--   BIGINT return_count, return_units → INT64
--   DECIMAL(16,2) total_refunded → NUMERIC(16,2)
--   DECIMAL(8,2) avg_days_to_return → NUMERIC(8,2)
CREATE TABLE `acme-analytics-prod.retail.agg_returns_by_reason_monthly` (
  reason_code        STRING,
  return_count       INT64,
  return_units       INT64,
  total_refunded     NUMERIC(16,2),
  avg_days_to_return NUMERIC(8,2),
  month_start        DATE
)
PARTITION BY month_start;
