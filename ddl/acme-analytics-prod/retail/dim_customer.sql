-- Source: retail.dim_customer (03-retail-tables.hql)
-- Storage: Parquet/Snappy → managed BQ table
-- Type mappings applied:
--   BIGINT customer_sk → INT64
--   TIMESTAMP first_seen_ts, last_seen_ts → DATETIME
CREATE TABLE `acme-analytics-prod.retail.dim_customer` (
  customer_sk   INT64,
  customer_id   STRING,
  country       STRING,
  first_seen_ts DATETIME,
  last_seen_ts  DATETIME
);
