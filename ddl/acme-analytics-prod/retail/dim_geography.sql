-- Source: retail.dim_geography (10-additional-dims.hql)
-- Storage: Parquet/Snappy → managed BQ table
-- Type mappings applied:
--   BIGINT geo_sk → INT64
--   DOUBLE latitude, longitude → FLOAT64
CREATE TABLE `acme-analytics-prod.retail.dim_geography` (
  geo_sk       INT64,
  country_iso2 STRING,
  country_name STRING,
  region_code  STRING,
  region_name  STRING,
  city         STRING,
  postal_code  STRING,
  timezone     STRING,
  latitude     FLOAT64,
  longitude    FLOAT64
);
