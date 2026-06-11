-- Source: retail.fact_chat_interactions (11-additional-facts.hql)
-- Storage: Parquet → managed BQ table
-- Partition: PARTITIONED BY (start_date DATE) → PARTITION BY start_date
-- Type mappings applied:
--   BIGINT customer_sk, agent_sk → INT64
--   TIMESTAMP started_at, ended_at → DATETIME
--   INT duration_sec, message_count, csat_score → INT64
--   BOOLEAN resolved → BOOL
--   DECIMAL(4,3) sentiment_avg → NUMERIC(4,3)
CREATE TABLE `acme-analytics-prod.retail.fact_chat_interactions` (
  chat_id       STRING,
  customer_sk   INT64,
  agent_sk      INT64,
  started_at    DATETIME,
  ended_at      DATETIME,
  duration_sec  INT64,
  message_count INT64,
  resolved      BOOL,
  csat_score    INT64,
  sentiment_avg NUMERIC(4,3),
  start_date    DATE
)
PARTITION BY start_date;
