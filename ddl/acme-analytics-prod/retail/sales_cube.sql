-- Source: retail.sales_cube (08-rollup-etl.hql)
-- Storage: Parquet/Snappy → managed BQ table
-- Partition: PARTITIONED BY (as_of_date DATE) → PARTITION BY as_of_date
-- Type mappings applied:
--   TINYINT dim_level → INT64 (R6 NARROW_INT)
--   SMALLINT month_key → INT64 (R6 NARROW_INT)
--   BIGINT product_sk, orders, units → INT64
--   DECIMAL(18,2) revenue → NUMERIC(18,2)
CREATE TABLE `acme-analytics-prod.retail.sales_cube` (
  dim_level  INT64,
  cube_key   STRING,
  country    STRING,
  month_key  INT64,
  product_sk INT64,
  orders     INT64,
  revenue    NUMERIC(18,2),
  units      INT64,
  as_of_date DATE
)
PARTITION BY as_of_date;
