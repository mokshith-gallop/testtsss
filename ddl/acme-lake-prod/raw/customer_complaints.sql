-- Source: raw.customer_complaints (05-additional-raw-feeds.hql)
-- Storage: TEXTFILE (TSV) → managed BQ table
-- Partition: date_ts STRING → ingestion-time partitioning
CREATE TABLE `acme-lake-prod.raw.customer_complaints` (
  complaint_id  STRING,
  customer_id   STRING,
  invoice_no    STRING,
  channel       STRING,
  severity      STRING,
  summary       STRING,
  body          STRING,
  created_at    DATETIME,
  resolved_at   DATETIME,
  csat_score    INT64,
  -- Hive partition column inlined
  date_ts       STRING
)
PARTITION BY DATE(_PARTITIONTIME);
