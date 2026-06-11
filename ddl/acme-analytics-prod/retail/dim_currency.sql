-- Source: retail.dim_currency (10-additional-dims.hql)
-- Storage: Parquet/Snappy → managed BQ table
-- Type mappings applied:
--   INT minor_unit → INT64
CREATE TABLE `acme-analytics-prod.retail.dim_currency` (
  currency_code STRING,
  currency_name STRING,
  minor_unit    INT64,
  symbol        STRING
);
