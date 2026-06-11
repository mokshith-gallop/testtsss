-- Source: staging.parsed_loyalty_events (06-staging-tables.hql)
-- Storage: PARQUET → managed BQ table
-- Type mappings: MAP<STRING,STRING>→JSON, INT→INT64, TIMESTAMP→DATETIME
-- Partition: date_ts STRING → ingestion-time partitioning
CREATE TABLE `acme-lake-prod.staging.parsed_loyalty_events` (
  event_ts       DATETIME,
  member_id      STRING,
  event_type     STRING,
  points         INT64,
  store_id       STRING,
  tx_id          STRING,
  meta           JSON,
  -- Hive partition column inlined
  date_ts        STRING
)
PARTITION BY DATE(_PARTITIONTIME);
