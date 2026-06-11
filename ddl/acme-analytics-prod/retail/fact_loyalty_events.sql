-- Source: retail.fact_loyalty_events (11-additional-facts.hql)
-- Storage: Parquet → managed BQ table
-- Partition: PARTITIONED BY (event_date DATE) → PARTITION BY event_date
-- Type mappings applied:
--   BIGINT event_id, store_sk → INT64
--   INT points → INT64
--   TIMESTAMP event_ts → DATETIME
--   MAP<STRING,STRING> meta → JSON
CREATE TABLE `acme-analytics-prod.retail.fact_loyalty_events` (
  event_id   INT64,
  member_id  STRING,
  event_type STRING,
  points     INT64,
  store_sk   INT64,
  tx_id      STRING,
  event_ts   DATETIME,
  meta       JSON,
  event_date DATE
)
PARTITION BY event_date;
