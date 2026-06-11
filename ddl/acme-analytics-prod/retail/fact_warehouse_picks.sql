-- Source: retail.fact_warehouse_picks (11-additional-facts.hql)
-- Storage: Parquet → managed BQ table
-- Partition: PARTITIONED BY (pick_date DATE, warehouse_partition STRING)
--   → PARTITION BY pick_date; warehouse_partition inlined as regular column
-- Cluster: CLUSTERED BY (picker_sk) INTO 8 BUCKETS → CLUSTER BY picker_sk
-- Type mappings applied:
--   BIGINT pick_id, warehouse_sk, picker_sk → INT64
--   INT quantity, duration_ms → INT64
--   TIMESTAMP picked_ts → DATETIME
CREATE TABLE `acme-analytics-prod.retail.fact_warehouse_picks` (
  pick_id             INT64,
  warehouse_sk        INT64,
  picker_sk           INT64,
  sku                 STRING,
  quantity            INT64,
  picked_ts           DATETIME,
  duration_ms         INT64,
  bin_location        STRING,
  -- Hive partition columns inlined
  pick_date           DATE,
  warehouse_partition STRING
)
PARTITION BY pick_date
CLUSTER BY picker_sk;
