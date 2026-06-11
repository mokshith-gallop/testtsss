-- Source: raw.return_authorizations (05-additional-raw-feeds.hql)
-- Storage: TEXTFILE (TSV) → managed BQ table
-- Partition: date_ts STRING → ingestion-time partitioning
CREATE TABLE `acme-lake-prod.raw.return_authorizations` (
  rma_id         STRING,
  customer_id    STRING,
  invoice_no     STRING,
  stock_code     STRING,
  quantity       INT64,
  reason_code    STRING,
  reason_text    STRING,
  requested_at   DATETIME,
  approved       BOOL,
  refund_amount  NUMERIC(12,2),
  -- Hive partition column inlined
  date_ts        STRING
)
PARTITION BY DATE(_PARTITIONTIME);
