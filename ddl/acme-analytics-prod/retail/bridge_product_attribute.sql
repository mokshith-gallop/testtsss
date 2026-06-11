-- Source: retail.bridge_product_attribute (15-bridge-and-scd2.hql)
-- Storage: Parquet → managed BQ table
-- Type mappings applied:
--   BIGINT product_sk → INT64
--   BOOLEAN primary_value → BOOL
--   INT sort_order → INT64
CREATE TABLE `acme-analytics-prod.retail.bridge_product_attribute` (
  product_sk      INT64,
  attribute_name  STRING,
  attribute_value STRING,
  primary_value   BOOL,
  sort_order      INT64
);
