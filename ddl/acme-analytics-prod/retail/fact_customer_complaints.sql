-- Source: retail.fact_customer_complaints (11-additional-facts.hql)
-- Storage: Parquet → managed BQ table
-- Partition: PARTITIONED BY (created_date DATE) → PARTITION BY created_date
-- Type mappings applied:
--   BIGINT customer_sk → INT64
--   TIMESTAMP created_at, resolved_at → DATETIME
--   INT csat_score → INT64
CREATE TABLE `acme-analytics-prod.retail.fact_customer_complaints` (
  complaint_id STRING,
  customer_sk  INT64,
  invoice_no   STRING,
  channel      STRING,
  severity     STRING,
  summary      STRING,
  created_at   DATETIME,
  resolved_at  DATETIME,
  csat_score   INT64,
  created_date DATE
)
PARTITION BY created_date;
