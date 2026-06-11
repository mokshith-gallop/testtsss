-- Source: raw.driver_logs (05-additional-raw-feeds.hql)
-- Storage: TEXTFILE with JsonSerDe → managed BQ table
-- Type mappings:
--   STRUCT<lat:DOUBLE, lon:DOUBLE> gps → STRUCT<lat FLOAT64, lon FLOAT64>
--   MAP<STRING,STRING> extras → JSON
-- Partition: date_ts STRING → ingestion-time partitioning
CREATE TABLE `acme-lake-prod.raw.driver_logs` (
  driver_id    STRING,
  event_ts     DATETIME,
  event_type   STRING,
  gps          STRUCT<lat FLOAT64, lon FLOAT64>,
  notes        STRING,
  extras       JSON,
  -- Hive partition column inlined
  date_ts      STRING
)
PARTITION BY DATE(_PARTITIONTIME);
