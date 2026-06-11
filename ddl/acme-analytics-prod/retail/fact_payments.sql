-- Source: retail.fact_payments (11-additional-facts.hql)
-- Storage: Parquet → managed BQ table
-- Partition: PARTITIONED BY (post_year INT, post_month INT, payment_method_partition STRING)
--   → Synthetic _partition_month DATE; original partition cols inlined as regular columns
--   ETL must populate: _partition_month = DATE(post_year, post_month, 1)
-- Cluster: CLUSTERED BY (invoice_no) INTO 16 BUCKETS → CLUSTER BY invoice_no
-- Type mappings applied:
--   BIGINT payment_id, customer_sk, payment_method_sk → INT64
--   DECIMAL(14,2) amount → NUMERIC(14,2)
--   DECIMAL(10,2) fee_amount → NUMERIC(10,2)
--   TIMESTAMP payment_ts → DATETIME
--   INT post_year, post_month → INT64 (inlined partition cols)
CREATE TABLE `acme-analytics-prod.retail.fact_payments` (
  payment_id              INT64,
  invoice_no              STRING,
  customer_sk             INT64,
  payment_method_sk       INT64,
  amount                  NUMERIC(14,2),
  currency_code           STRING,
  payment_ts              DATETIME,
  auth_code               STRING,
  settlement_id           STRING,
  fee_amount              NUMERIC(10,2),
  -- Inlined partition columns (were PARTITIONED BY in Hive)
  post_year               INT64,
  post_month              INT64,
  payment_method_partition STRING,
  -- Synthetic partition column
  _partition_month        DATE
)
PARTITION BY DATE_TRUNC(_partition_month, MONTH)
CLUSTER BY invoice_no;
