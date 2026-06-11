-- Source: retail.fact_returns (11-additional-facts.hql)
-- Storage: Parquet → managed BQ table
-- Partition: PARTITIONED BY (return_date DATE) → PARTITION BY return_date
-- Type mappings applied:
--   BIGINT return_id, invoice_no → INT64; STRING invoice_no stays STRING
--   BIGINT customer_sk, product_sk, store_sk → INT64
--   INT quantity → INT64
--   TIMESTAMP return_ts → DATETIME
--   DECIMAL(12,2) refund_amount → NUMERIC(12,2)
CREATE TABLE `acme-analytics-prod.retail.fact_returns` (
  return_id      INT64,
  invoice_no     STRING,
  customer_sk    INT64,
  product_sk     INT64,
  return_ts      DATETIME,
  quantity       INT64,
  refund_amount  NUMERIC(12,2),
  reason_code    STRING,
  return_channel STRING,
  store_sk       INT64,
  return_date    DATE
)
PARTITION BY return_date;
