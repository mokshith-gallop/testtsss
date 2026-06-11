-- Source: retail.dim_size (10-additional-dims.hql)
-- Storage: Parquet/Snappy → managed BQ table
-- Type mappings applied:
--   BIGINT size_sk → INT64
--   INT sort_order → INT64
CREATE TABLE `acme-analytics-prod.retail.dim_size` (
  size_sk     INT64,
  size_code   STRING,
  size_name   STRING,
  size_system STRING,
  sort_order  INT64
);
