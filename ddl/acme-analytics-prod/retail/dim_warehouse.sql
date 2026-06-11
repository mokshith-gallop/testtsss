-- Source: retail.dim_warehouse (10-additional-dims.hql)
-- Storage: Parquet/Snappy → managed BQ table
-- Type mappings applied:
--   BIGINT warehouse_sk, capacity_units → INT64
--   STRUCT<lat:DOUBLE,lon:DOUBLE> geocode → STRUCT<lat FLOAT64, lon FLOAT64>
CREATE TABLE `acme-analytics-prod.retail.dim_warehouse` (
  warehouse_sk   INT64,
  warehouse_id   STRING,
  name           STRING,
  type           STRING,
  operator       STRING,
  region         STRING,
  capacity_units INT64,
  open_dt        DATE,
  geocode        STRUCT<lat FLOAT64, lon FLOAT64>
);
