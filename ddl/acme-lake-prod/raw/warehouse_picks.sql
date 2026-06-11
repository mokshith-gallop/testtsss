-- Source: raw.warehouse_picks (05-additional-raw-feeds.hql)
-- Storage: PARQUET → managed BQ table
-- Partition: date_ts STRING, warehouse_id_partition STRING
--   → ingestion-time partitioning (date_ts is STRING)
--   → warehouse_id_partition becomes CLUSTER BY column
CREATE TABLE `acme-lake-prod.raw.warehouse_picks` (
  pick_id                INT64,
  warehouse_id           STRING,
  bin_id                 STRING,
  sku                    STRING,
  picker_id              STRING,
  quantity               INT64,
  picked_at              DATETIME,
  duration_ms            INT64,
  -- Hive partition columns inlined
  date_ts                STRING,
  warehouse_id_partition STRING
)
PARTITION BY DATE(_PARTITIONTIME)
CLUSTER BY warehouse_id_partition;
