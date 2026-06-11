-- Source: staging.dedup_clickstream (06-staging-tables.hql)
-- Storage: PARQUET → managed BQ table
-- Partition: date_ts STRING, country_partition STRING
--   → ingestion-time partitioning (date_ts is STRING)
--   → CLUSTERED BY (user_id) INTO 16 BUCKETS → CLUSTER BY user_id, country_partition
--     (bucket count dropped — BQ manages it automatically)
CREATE TABLE `acme-lake-prod.staging.dedup_clickstream` (
  session_id     STRING,
  user_id        STRING,
  event_ts       DATETIME,
  page_url       STRING,
  referrer_url   STRING,
  ip             STRING,
  country        STRING,
  bot_score      NUMERIC(4,3),
  device_type    STRING,
  -- Hive partition columns inlined
  date_ts        STRING,
  country_partition STRING
)
PARTITION BY DATE(_PARTITIONTIME)
CLUSTER BY user_id, country_partition;
