-- Source: raw.chat_transcripts (05-additional-raw-feeds.hql)
-- Storage: TEXTFILE (TSV) → managed BQ table
-- Partition: date_ts STRING → ingestion-time partitioning
CREATE TABLE `acme-lake-prod.raw.chat_transcripts` (
  chat_id        STRING,
  customer_id    STRING,
  agent_id       STRING,
  started_at     DATETIME,
  ended_at       DATETIME,
  duration_sec   INT64,
  message_count  INT64,
  transcript     STRING,
  sentiment      NUMERIC(4,3),
  -- Hive partition column inlined
  date_ts        STRING
)
PARTITION BY DATE(_PARTITIONTIME);
