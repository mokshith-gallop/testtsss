-- Source: raw.loyalty_events (05-additional-raw-feeds.hql)
-- Storage: TEXTFILE with RegexSerDe → managed BQ table
-- ROW FORMAT SERDE / WITH SERDEPROPERTIES dropped
-- Partition: date_ts STRING → ingestion-time partitioning
CREATE TABLE `acme-lake-prod.raw.loyalty_events` (
  event_ts_str   STRING,
  member_id      STRING,
  event_type     STRING,
  points         STRING,
  store_id       STRING,
  tx_id          STRING,
  meta_raw       STRING,
  -- Hive partition column inlined
  date_ts        STRING
)
PARTITION BY DATE(_PARTITIONTIME);
