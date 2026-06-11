-- Source: retail.dim_color (10-additional-dims.hql)
-- Storage: Parquet/Snappy → managed BQ table
-- Type mappings applied:
--   BIGINT color_sk → INT64
CREATE TABLE `acme-analytics-prod.retail.dim_color` (
  color_sk     INT64,
  color_code   STRING,
  color_name   STRING,
  color_family STRING,
  hex_code     STRING
);
