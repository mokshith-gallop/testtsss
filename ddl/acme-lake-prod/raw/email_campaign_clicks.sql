-- Source: raw.email_campaign_clicks (05-additional-raw-feeds.hql)
-- Storage: TEXTFILE with JsonSerDe → managed BQ table
-- Type mappings:
--   STRUCT<country,region,city> geo → STRUCT (recursive)
--   MAP<STRING,STRING> utm → JSON
-- Partition: date_ts STRING → ingestion-time partitioning
CREATE TABLE `acme-lake-prod.raw.email_campaign_clicks` (
  campaign_id  STRING,
  send_id      STRING,
  recipient    STRING,
  clicked_at   DATETIME,
  click_url    STRING,
  user_agent   STRING,
  ip_address   STRING,
  geo          STRUCT<country STRING, region STRING, city STRING>,
  utm          JSON,
  -- Hive partition column inlined
  date_ts      STRING
)
PARTITION BY DATE(_PARTITIONTIME);
