-- Source: retail.dim_product (03-retail-tables.hql)
-- Storage: Parquet/Snappy → managed BQ table
-- Type mappings applied:
--   BIGINT product_sk → INT64
--   DECIMAL(10,2) unit_price → NUMERIC(10,2)
CREATE TABLE `acme-analytics-prod.retail.dim_product` (
  product_sk  INT64,
  stock_code  STRING,
  description STRING,
  unit_price  NUMERIC(10,2)
);
