-- Source: retail.fact_web_session (03-retail-tables.hql)
-- Storage: Parquet/Snappy → managed BQ table
-- Partition: PARTITIONED BY (event_date DATE, country STRING) → PARTITION BY event_date
--   country inlined as regular column (BQ does not support STRING partition cols)
-- Type mappings applied:
--   TIMESTAMP event_ts → DATETIME
CREATE TABLE `acme-analytics-prod.retail.fact_web_session` (
  event_ts   DATETIME,
  ip         STRING,
  url        STRING,
  user_id    STRING,
  city       STRING,
  state      STRING,
  -- Hive partition columns inlined
  event_date DATE,
  country    STRING
)
PARTITION BY event_date;
