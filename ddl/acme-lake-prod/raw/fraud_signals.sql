-- Source: raw.fraud_signals (05-additional-raw-feeds.hql)
-- Storage: AVRO → managed BQ table
-- Schema: inlined from fraud_signals-v5.avsc (7 fields)
-- Avro mappings:
--   union [null, string] → STRING NULLABLE
--   union [null, double] → FLOAT64 NULLABLE
--   union [null, array<string>] → ARRAY<STRING> (REPEATED)
--   union [null, long{timestamp-millis}] → TIMESTAMP (Avro logical type)
-- Partition: signal_date STRING → ingestion-time partitioning
CREATE TABLE `acme-lake-prod.raw.fraud_signals` (
  customer_id    STRING,
  signal_type    STRING,
  score          FLOAT64,
  risk_band      STRING,
  reason_codes   ARRAY<STRING>,
  signal_ts      TIMESTAMP,
  vendor         STRING,
  -- Hive partition column inlined
  signal_date    STRING
)
PARTITION BY DATE(_PARTITIONTIME);
