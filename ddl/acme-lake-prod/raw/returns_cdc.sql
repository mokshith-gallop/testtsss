-- Source: raw.returns_cdc (02-raw-external-tables.hql)
-- Storage: TEXTFILE (CSV) → managed BQ table
-- Partition: snapshot_date DATE → direct DATE partitioning
-- Note: CDC feed consumed by analytics-side MERGE into retail.returns_ledger
CREATE TABLE `acme-lake-prod.raw.returns_cdc` (
  return_id      INT64,
  invoice_no     STRING,
  customer_sk    INT64,
  return_ts      DATETIME,
  refund_amount  NUMERIC(12,2),
  reason_code    STRING,
  status         STRING,
  op             STRING,
  -- Hive partition column inlined (DATE type maps directly)
  snapshot_date  DATE
)
PARTITION BY snapshot_date;
