-- Source: raw.pos_transactions (05-additional-raw-feeds.hql)
-- Storage: PARQUET → managed BQ table
-- Partition: date_ts STRING → ingestion-time partitioning
CREATE TABLE `acme-lake-prod.raw.pos_transactions` (
  txn_id          INT64,
  store_id        STRING,
  register_id     STRING,
  cashier_id      STRING,
  customer_id     STRING,
  invoice_no      STRING,
  txn_ts          DATETIME,
  line_count      INT64,
  gross_amount    NUMERIC(14,2),
  discount_amount NUMERIC(14,2),
  tax_amount      NUMERIC(14,2),
  tender_type     STRING,
  void_flag       BOOL,
  -- Hive partition column inlined
  date_ts         STRING
)
PARTITION BY DATE(_PARTITIONTIME);
