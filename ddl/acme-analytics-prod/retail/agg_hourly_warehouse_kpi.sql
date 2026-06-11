-- Source: retail.agg_hourly_warehouse_kpi (12-aggregates-rollups.hql)
-- Storage: Parquet → managed BQ table
-- Partition: PARTITIONED BY (snapshot_hour STRING)
--   → Synthetic _partition_date DATE; snapshot_hour inlined as regular STRING column
--   ETL must populate: _partition_date = DATE(PARSE_DATETIME('%Y%m%d_%H', snapshot_hour))
-- Type mappings applied:
--   BIGINT warehouse_sk → INT64
--   INT units_in, units_picked, units_shipped, backlog_units → INT64
--   DECIMAL(8,2) pick_rate_uph, avg_pick_seconds → NUMERIC(8,2)
CREATE TABLE `acme-analytics-prod.retail.agg_hourly_warehouse_kpi` (
  warehouse_sk     INT64,
  units_in         INT64,
  units_picked     INT64,
  units_shipped    INT64,
  pick_rate_uph    NUMERIC(8,2),
  backlog_units    INT64,
  avg_pick_seconds NUMERIC(8,2),
  -- Hive partition column inlined
  snapshot_hour    STRING,
  -- Synthetic partition column
  _partition_date  DATE
)
PARTITION BY _partition_date;
