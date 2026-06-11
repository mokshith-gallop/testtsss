-- Source: raw.shipment_tracking (05-additional-raw-feeds.hql)
-- Storage: TEXTFILE (CSV) → managed BQ table
-- Partition: date_ts STRING, carrier_partition STRING
--   → ingestion-time partitioning (date_ts is STRING)
--   → carrier_partition becomes CLUSTER BY column
CREATE TABLE `acme-lake-prod.raw.shipment_tracking` (
  tracking_no       STRING,
  carrier           STRING,
  invoice_no        STRING,
  customer_id       STRING,
  shipped_at        DATETIME,
  delivered_at      DATETIME,
  status            STRING,
  last_location     STRING,
  estimated_eta     DATETIME,
  -- Hive partition columns inlined
  date_ts           STRING,
  carrier_partition STRING
)
PARTITION BY DATE(_PARTITIONTIME)
CLUSTER BY carrier_partition;
