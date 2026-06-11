-- Source: retail.fact_inventory_movements (11-additional-facts.hql)
-- Storage: Parquet/Snappy → managed BQ table
-- Partition: PARTITIONED BY (year INT, month INT, day INT, region STRING)
--   → Synthetic _partition_date DATE; original partition cols inlined as regular columns
--   ETL must populate: _partition_date = DATE(year, month, day)
-- Cluster: CLUSTERED BY (sku) INTO 32 BUCKETS → CLUSTER BY sku
-- Type mappings applied:
--   BIGINT movement_id, warehouse_sk, store_sk, operator_sk → INT64
--   TIMESTAMP movement_ts → DATETIME
--   INT quantity → INT64
--   INT year, month, day → INT64 (inlined partition cols)
CREATE TABLE `acme-analytics-prod.retail.fact_inventory_movements` (
  movement_id    INT64,
  movement_ts    DATETIME,
  sku            STRING,
  warehouse_sk   INT64,
  store_sk       INT64,
  movement_type  STRING,
  quantity       INT64,
  reference_doc  STRING,
  reason_code    STRING,
  operator_sk    INT64,
  -- Inlined partition columns (were PARTITIONED BY in Hive)
  year           INT64,
  month          INT64,
  day            INT64,
  region         STRING,
  -- Synthetic partition column
  _partition_date DATE
)
PARTITION BY _partition_date
CLUSTER BY sku;
