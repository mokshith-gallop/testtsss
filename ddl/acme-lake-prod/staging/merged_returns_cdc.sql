-- Source: staging.merged_returns_cdc (06-staging-tables.hql)
-- Storage: PARQUET → managed BQ table
-- Type mappings: BIGINT→INT64, BOOLEAN→BOOL, TIMESTAMP→DATETIME, DECIMAL→NUMERIC
-- Partition: snapshot_date DATE → direct DATE partitioning
CREATE TABLE `acme-lake-prod.staging.merged_returns_cdc` (
  return_id      INT64,
  invoice_no     STRING,
  customer_sk    INT64,
  return_ts      DATETIME,
  refund_amount  NUMERIC(12,2),
  reason_code    STRING,
  status         STRING,
  is_deleted     BOOL,
  -- Hive partition column inlined (DATE type maps directly)
  snapshot_date  DATE
)
PARTITION BY snapshot_date;
