-- Source: staging.warehouse_kpi_snapshot (06-staging-tables.hql)
-- Storage: PARQUET → managed BQ table
-- Type mappings: INT→INT64, DECIMAL→NUMERIC, TIMESTAMP→DATETIME
-- Partition: date_ts STRING → ingestion-time partitioning
CREATE TABLE `acme-lake-prod.staging.warehouse_kpi_snapshot` (
  warehouse_id   STRING,
  snapshot_ts    DATETIME,
  units_in       INT64,
  units_picked   INT64,
  units_shipped  INT64,
  pick_rate_uph  NUMERIC(8,2),
  backlog_units  INT64,
  avg_pick_ms    INT64,
  -- Hive partition column inlined
  date_ts        STRING
)
PARTITION BY DATE(_PARTITIONTIME);
