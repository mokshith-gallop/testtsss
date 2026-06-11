-- Source: retail.fact_app_clicks (11-additional-facts.hql)
-- Storage: Parquet → managed BQ table
-- Partition: PARTITIONED BY (event_date DATE, platform_partition STRING)
--   → PARTITION BY event_date; platform_partition inlined as regular column
-- Type mappings applied:
--   BIGINT user_sk → INT64
--   TIMESTAMP event_ts → DATETIME
--   MAP<STRING,STRING> properties → JSON
--   STRUCT<platform:STRING,version:STRING,model:STRING> device → STRUCT
CREATE TABLE `acme-analytics-prod.retail.fact_app_clicks` (
  session_id          STRING,
  user_sk             INT64,
  event_ts            DATETIME,
  event_type          STRING,
  screen              STRING,
  target_id           STRING,
  properties          JSON,
  device              STRUCT<platform STRING, version STRING, model STRING>,
  -- Hive partition columns inlined
  event_date          DATE,
  platform_partition  STRING
)
PARTITION BY event_date;
