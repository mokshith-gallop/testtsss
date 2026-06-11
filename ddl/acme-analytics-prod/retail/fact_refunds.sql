-- Source: retail.fact_refunds (11-additional-facts.hql)
-- Storage: Parquet → managed BQ table
-- Partition: PARTITIONED BY (refund_date DATE) → PARTITION BY refund_date
-- Type mappings applied:
--   BIGINT refund_id, payment_id, return_id, customer_sk → INT64
--   DECIMAL(14,2) amount → NUMERIC(14,2)
--   TIMESTAMP refund_ts → DATETIME
CREATE TABLE `acme-analytics-prod.retail.fact_refunds` (
  refund_id     INT64,
  payment_id    INT64,
  return_id     INT64,
  customer_sk   INT64,
  amount        NUMERIC(14,2),
  currency_code STRING,
  refund_ts     DATETIME,
  refund_method STRING,
  refund_date   DATE
)
PARTITION BY refund_date;
