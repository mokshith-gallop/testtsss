-- Source: retail.acid_inventory_adjustments_log (13-additional-acid-tables.hql)
-- Storage: ORC/Snappy (ACID, transactional=true) → managed BQ table
-- ACID handling: transactional properties dropped; BQ supports DML natively
-- Cluster: CLUSTERED BY (adjustment_id) INTO 4 BUCKETS → CLUSTER BY adjustment_id
-- Type mappings applied:
--   BIGINT adjustment_id, warehouse_sk → INT64
--   INT quantity_delta → INT64
--   TIMESTAMP adjusted_at, approved_at → DATETIME
CREATE TABLE `acme-analytics-prod.retail.acid_inventory_adjustments_log` (
  adjustment_id INT64,
  warehouse_sk  INT64,
  sku           STRING,
  quantity_delta INT64,
  reason_code   STRING,
  notes         STRING,
  adjusted_by   STRING,
  adjusted_at   DATETIME,
  approved_by   STRING,
  approved_at   DATETIME
)
CLUSTER BY adjustment_id;
