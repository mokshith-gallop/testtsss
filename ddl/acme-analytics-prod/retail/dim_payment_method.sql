-- Source: retail.dim_payment_method (10-additional-dims.hql)
-- Storage: Parquet/Snappy → managed BQ table
-- Type mappings applied:
--   BIGINT payment_method_sk → INT64
--   DECIMAL(5,4) fee_pct → NUMERIC(5,4)
--   DECIMAL(8,2) fee_flat → NUMERIC(8,2)
--   INT settlement_days → INT64
CREATE TABLE `acme-analytics-prod.retail.dim_payment_method` (
  payment_method_sk INT64,
  method_code       STRING,
  method_name       STRING,
  category          STRING,
  fee_pct           NUMERIC(5,4),
  fee_flat          NUMERIC(8,2),
  settlement_days   INT64
);
