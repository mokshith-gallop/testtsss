-- Source: retail.top_countries_daily (08-rollup-etl.hql)
-- Storage: Parquet/Snappy → managed BQ table
-- No partition (as_of_date is a regular column, not a Hive partition)
-- Type mappings applied:
--   BIGINT orders → INT64
--   DECIMAL(18,2) revenue → NUMERIC(18,2)
--   TINYINT rank → INT64 (R6 NARROW_INT)
CREATE TABLE `acme-analytics-prod.retail.top_countries_daily` (
  as_of_date DATE,
  country    STRING,
  orders     INT64,
  revenue    NUMERIC(18,2),
  rank       INT64
);
