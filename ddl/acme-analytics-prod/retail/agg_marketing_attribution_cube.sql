-- Source: retail.agg_marketing_attribution_cube (12-aggregates-rollups.hql)
-- Storage: Parquet → managed BQ table
-- Partition: PARTITIONED BY (period_date DATE) → PARTITION BY period_date
-- Type mappings applied:
--   BIGINT campaign_sk, attributed_units → INT64
--   DECIMAL(16,2) attributed_revenue → NUMERIC(16,2)
--   DECIMAL(14,2) cost → NUMERIC(14,2)
--   DECIMAL(8,4) roas → NUMERIC(8,4)
--   INT grouping_id → INT64
CREATE TABLE `acme-analytics-prod.retail.agg_marketing_attribution_cube` (
  channel            STRING,
  campaign_sk        INT64,
  region             STRING,
  attributed_revenue NUMERIC(16,2),
  attributed_units   INT64,
  cost               NUMERIC(14,2),
  roas               NUMERIC(8,4),
  grouping_id        INT64,
  period_date        DATE
)
PARTITION BY period_date;
