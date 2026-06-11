-- Source: retail.kudu_session_state (14-kudu-realtime.hql)
-- Storage: Kudu → managed BQ table
-- Kudu handling: PRIMARY KEY, PARTITION BY HASH, STORED AS KUDU, TBLPROPERTIES dropped
-- Cluster: PRIMARY KEY (session_id) → CLUSTER BY session_id
-- Type mappings applied:
--   BIGINT started_ts, last_event_ts → INT64
--   DECIMAL(12,2) cart_value → NUMERIC(12,2)
--   INT cart_items → INT64
CREATE TABLE `acme-analytics-prod.retail.kudu_session_state` (
  session_id     STRING,
  user_id        STRING,
  started_ts     INT64,
  last_event_ts  INT64,
  cart_value     NUMERIC(12,2),
  cart_items     INT64,
  current_screen STRING,
  platform       STRING,
  geo_country    STRING
)
CLUSTER BY session_id;
