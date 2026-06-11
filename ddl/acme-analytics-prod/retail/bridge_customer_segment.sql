-- Source: retail.bridge_customer_segment (15-bridge-and-scd2.hql)
-- Storage: Parquet → managed BQ table
-- Partition: PARTITIONED BY (snapshot_date DATE) → PARTITION BY snapshot_date
-- Type mappings applied:
--   BIGINT customer_sk → INT64
--   DECIMAL(4,3) confidence → NUMERIC(4,3)
CREATE TABLE `acme-analytics-prod.retail.bridge_customer_segment` (
  customer_sk  INT64,
  segment_id   STRING,
  segment_name STRING,
  assigned_dt  DATE,
  expires_dt   DATE,
  confidence   NUMERIC(4,3),
  source       STRING,
  snapshot_date DATE
)
PARTITION BY snapshot_date;
