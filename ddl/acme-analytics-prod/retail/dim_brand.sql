-- Source: retail.dim_brand (10-additional-dims.hql)
-- Storage: Parquet/Snappy → managed BQ table
-- Type mappings applied:
--   BIGINT brand_sk → INT64
--   BOOLEAN private_label → BOOL
CREATE TABLE `acme-analytics-prod.retail.dim_brand` (
  brand_sk       INT64,
  brand_id       STRING,
  brand_name     STRING,
  parent_company STRING,
  private_label  BOOL,
  launch_dt      DATE
);
