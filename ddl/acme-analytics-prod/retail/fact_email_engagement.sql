-- Source: retail.fact_email_engagement (11-additional-facts.hql)
-- Storage: Parquet → managed BQ table
-- Partition: PARTITIONED BY (event_date DATE) → PARTITION BY event_date
-- Type mappings applied:
--   BIGINT campaign_sk, user_sk → INT64
--   TIMESTAMP event_ts → DATETIME
--   ARRAY<STRUCT<ts:TIMESTAMP,url:STRING>> clicks
--     → ARRAY<STRUCT<ts DATETIME, url STRING>>
CREATE TABLE `acme-analytics-prod.retail.fact_email_engagement` (
  send_id     STRING,
  campaign_sk INT64,
  user_sk     INT64,
  event_type  STRING,
  event_ts    DATETIME,
  link_url    STRING,
  clicks      ARRAY<STRUCT<ts DATETIME, url STRING>>,
  event_date  DATE
)
PARTITION BY event_date;
