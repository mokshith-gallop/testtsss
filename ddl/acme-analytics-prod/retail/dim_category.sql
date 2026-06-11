-- Source: retail.dim_category (10-additional-dims.hql)
-- Storage: Parquet/Snappy → managed BQ table
-- Type mappings applied:
--   BIGINT category_sk → INT64
--   INT depth, sort_order → INT64
CREATE TABLE `acme-analytics-prod.retail.dim_category` (
  category_sk INT64,
  category_id STRING,
  parent_id   STRING,
  name        STRING,
  depth       INT64,
  sort_order  INT64
);
