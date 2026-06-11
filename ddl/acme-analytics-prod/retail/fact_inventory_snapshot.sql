-- Source: retail.fact_inventory_snapshot (11-additional-facts.hql)
-- Storage: Parquet → managed BQ table
-- Partition: PARTITIONED BY (snapshot_date DATE) → PARTITION BY snapshot_date
-- Cluster: CLUSTERED BY (sku) INTO 16 BUCKETS → CLUSTER BY sku
-- Type mappings applied:
--   BIGINT warehouse_sk → INT64
--   INT on_hand_units, allocated_units, in_transit_units, available_units → INT64
--   DECIMAL(12,4) avg_cost → NUMERIC(12,4)
--   TIMESTAMP last_movement_ts → DATETIME
CREATE TABLE `acme-analytics-prod.retail.fact_inventory_snapshot` (
  sku              STRING,
  warehouse_sk     INT64,
  on_hand_units    INT64,
  allocated_units  INT64,
  in_transit_units INT64,
  available_units  INT64,
  avg_cost         NUMERIC(12,4),
  last_movement_ts DATETIME,
  snapshot_date    DATE
)
PARTITION BY snapshot_date
CLUSTER BY sku;
