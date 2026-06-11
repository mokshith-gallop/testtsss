-- Source: retail.fact_fraud_decisions (11-additional-facts.hql)
-- Storage: Parquet → managed BQ table
-- Partition: PARTITIONED BY (decision_date DATE) → PARTITION BY decision_date
-- Type mappings applied:
--   BIGINT txn_id, customer_sk → INT64
--   DECIMAL(5,4) fraud_score → NUMERIC(5,4)
--   ARRAY<STRING> rule_signals → ARRAY<STRING> (REPEATED STRING)
--   TIMESTAMP decided_ts → DATETIME
CREATE TABLE `acme-analytics-prod.retail.fact_fraud_decisions` (
  txn_id        INT64,
  customer_sk   INT64,
  fraud_score   NUMERIC(5,4),
  decision      STRING,
  rule_signals  ARRAY<STRING>,
  decided_ts    DATETIME,
  decision_date DATE
)
PARTITION BY decision_date;
