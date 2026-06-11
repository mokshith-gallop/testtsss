-- Source: raw.customer_signups (05-additional-raw-feeds.hql)
-- Storage: AVRO → managed BQ table
-- Schema: inlined from customer_signups-v3.avsc (12 fields)
-- Avro union [null, T] → NULLABLE T
-- Avro boolean → BOOL
-- Partition: signup_date STRING → ingestion-time partitioning
CREATE TABLE `acme-lake-prod.raw.customer_signups` (
  customer_id      STRING,
  email            STRING,
  phone            STRING,
  first_name       STRING,
  last_name        STRING,
  addr_line1       STRING,
  addr_city        STRING,
  addr_region      STRING,
  addr_country     STRING,
  addr_postal      STRING,
  signup_source    STRING,
  marketing_opt_in BOOL,
  -- Hive partition column inlined
  signup_date      STRING
)
PARTITION BY DATE(_PARTITIONTIME);
