-- Source: staging.fraud_scored (06-staging-tables.hql)
-- Storage: PARQUET → managed BQ table
-- Type mappings: BIGINT→INT64, DECIMAL→NUMERIC, TIMESTAMP→DATETIME,
--   ARRAY<STRING>→ARRAY<STRING>
-- Partition: score_date DATE → direct DATE partitioning
CREATE TABLE `acme-lake-prod.staging.fraud_scored` (
  txn_id         INT64,
  customer_id    STRING,
  fraud_score    NUMERIC(5,4),
  risk_band      STRING,
  signals        ARRAY<STRING>,
  scored_at      DATETIME,
  -- Hive partition column inlined (DATE type maps directly)
  score_date     DATE
)
PARTITION BY score_date;
