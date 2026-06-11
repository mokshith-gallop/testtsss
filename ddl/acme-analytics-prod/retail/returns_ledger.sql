-- Source: retail.returns_ledger (06-acid-tables.hql)
-- Storage: ORC/Snappy (ACID, transactional=true) → managed BQ table
-- ACID handling: transactional properties dropped; BQ supports DML natively
-- Cluster: CLUSTERED BY (return_id) INTO 4 BUCKETS → CLUSTER BY return_id
-- Type mappings applied:
--   BIGINT return_id, customer_sk → INT64
--   TIMESTAMP return_ts → DATETIME
--   DECIMAL(12,2) refund_amount → NUMERIC(12,2)
CREATE TABLE `acme-analytics-prod.retail.returns_ledger` (
  return_id     INT64,
  invoice_no    STRING,
  customer_sk   INT64,
  return_ts     DATETIME,
  refund_amount NUMERIC(12,2),
  reason_code   STRING,
  status        STRING
)
CLUSTER BY return_id;
