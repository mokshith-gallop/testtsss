-- Source: retail.kudu_inventory_realtime (14-kudu-realtime.hql)
-- Renamed: kudu_inventory_realtime → inventory_realtime
-- Storage: Kudu → managed BQ table
-- Kudu handling: PRIMARY KEY, PARTITION BY HASH, STORED AS KUDU, TBLPROPERTIES dropped
-- Cluster: PRIMARY KEY (warehouse_id, sku) → CLUSTER BY warehouse_id, sku
-- Type mappings applied:
--   INT on_hand, allocated, available → INT64
--   BIGINT last_updated_ts → INT64
CREATE TABLE `acme-analytics-prod.retail.inventory_realtime` (
  warehouse_id    STRING,
  sku             STRING,
  on_hand         INT64,
  allocated       INT64,
  available       INT64,
  last_updated_ts INT64
)
CLUSTER BY warehouse_id, sku;
