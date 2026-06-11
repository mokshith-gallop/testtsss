-- Source: raw.inventory_movements (05-additional-raw-feeds.hql)
-- Storage: PARQUET → managed BQ table
-- Partition: year INT, month INT, day INT → ingestion-time partitioning
--   Year/month/day are preserved as INT64 columns; load scripts should
--   set the partition decorator based on DATE(year, month, day).
CREATE TABLE `acme-lake-prod.raw.inventory_movements` (
  movement_id    INT64,
  sku            STRING,
  warehouse_id   STRING,
  bin_location   STRING,
  movement_type  STRING,
  quantity       INT64,
  movement_ts    DATETIME,
  reference_doc  STRING,
  operator_id    STRING,
  reason_code    STRING,
  -- Hive partition columns inlined
  year           INT64,
  month          INT64,
  day            INT64
)
PARTITION BY DATE(_PARTITIONTIME);
