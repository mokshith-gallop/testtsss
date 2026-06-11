-- Source: retail.dim_promotion (10-additional-dims.hql)
-- Storage: Parquet/Snappy → managed BQ table
-- Type mappings applied:
--   BIGINT promo_sk → INT64
--   DECIMAL(5,2) pct_off → NUMERIC(5,2)
--   DECIMAL(10,2) flat_off → NUMERIC(10,2)
--   DECIMAL(14,2) budget → NUMERIC(14,2)
--   ARRAY<STRING> channels → REPEATED STRING
--   MAP<STRING,STRING> eligibility → JSON
CREATE TABLE `acme-analytics-prod.retail.dim_promotion` (
  promo_sk    INT64,
  promo_id    STRING,
  name        STRING,
  promo_type  STRING,
  pct_off     NUMERIC(5,2),
  flat_off    NUMERIC(10,2),
  start_dt    DATE,
  end_dt      DATE,
  budget      NUMERIC(14,2),
  channels    ARRAY<STRING>,
  eligibility JSON
);
