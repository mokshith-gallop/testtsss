-- Source: retail.fact_shipments (11-additional-facts.hql)
-- Storage: Parquet → managed BQ table
-- Partition: PARTITIONED BY (ship_year INT, ship_month INT, ship_day INT, carrier_partition STRING)
--   → Synthetic _partition_date DATE; original partition cols inlined as regular columns
--   ETL must populate: _partition_date = DATE(ship_year, ship_month, ship_day)
-- Cluster: CLUSTERED BY (warehouse_sk) INTO 16 BUCKETS → CLUSTER BY warehouse_sk
-- Type mappings applied:
--   BIGINT customer_sk, warehouse_sk → INT64
--   INT sla_hours → INT64
--   TIMESTAMP shipped_ts, delivered_ts → DATETIME
--   ARRAY<STRUCT<ts:TIMESTAMP,status:STRING,location:STRING>> tracking_events
--     → ARRAY<STRUCT<ts DATETIME, status STRING, location STRING>>
--   INT ship_year, ship_month, ship_day → INT64 (inlined partition cols)
CREATE TABLE `acme-analytics-prod.retail.fact_shipments` (
  shipment_id      STRING,
  invoice_no       STRING,
  customer_sk      INT64,
  warehouse_sk     INT64,
  carrier          STRING,
  tracking_no      STRING,
  shipped_ts       DATETIME,
  delivered_ts     DATETIME,
  sla_hours        INT64,
  tracking_events  ARRAY<STRUCT<ts DATETIME, status STRING, location STRING>>,
  -- Inlined partition columns (were PARTITIONED BY in Hive)
  ship_year        INT64,
  ship_month       INT64,
  ship_day         INT64,
  carrier_partition STRING,
  -- Synthetic partition column
  _partition_date  DATE
)
PARTITION BY _partition_date
CLUSTER BY warehouse_sk;
