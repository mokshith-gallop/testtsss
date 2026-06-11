-- Source: raw.mobile_events (07-json-raw.hql)
-- Storage: TEXTFILE (NDJSON via JsonSerDe) → managed BQ table
-- Partition: event_date STRING, hour_bucket TINYINT
--   → ingestion-time partitioning (event_date is STRING)
-- Type mappings applied:
--   TINYINT hour_bucket → INT64 (R6 NARROW_INT)
--   MAP<STRING,STRING> properties → JSON
--   STRUCT<ip,country,session_id,referrer> context → STRUCT (recursive)
--   ARRAY<STRUCT<sku,qty INT,price DECIMAL(10,2)>> items → ARRAY<STRUCT> (recursive)
CREATE TABLE `acme-lake-prod.raw.mobile_events` (
  event_id        STRING,
  event_ts        DATETIME,
  user_id         STRING,
  app_version     STRING,
  device_type     STRING,
  platform        STRING,
  properties      JSON,
  context         STRUCT<
                    ip         STRING,
                    country    STRING,
                    session_id STRING,
                    referrer   STRING
                  >,
  items           ARRAY<STRUCT<sku STRING, qty INT64, price NUMERIC(10,2)>>,
  -- Hive partition columns inlined
  event_date      STRING,
  hour_bucket     INT64
)
PARTITION BY DATE(_PARTITIONTIME);
