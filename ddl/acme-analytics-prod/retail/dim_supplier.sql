-- Source: retail.dim_supplier (10-additional-dims.hql)
-- Storage: Parquet/Snappy → managed BQ table
-- Type mappings applied:
--   BIGINT supplier_sk → INT64
--   INT payment_terms_days → INT64
--   STRUCT<name:STRING,email:STRING,phone:STRING> primary_contact → STRUCT
--   ARRAY<STRING> categories → REPEATED STRING
CREATE TABLE `acme-analytics-prod.retail.dim_supplier` (
  supplier_sk        INT64,
  supplier_id        STRING,
  supplier_name      STRING,
  country            STRING,
  tax_id             STRING,
  payment_terms_days INT64,
  onboard_dt         DATE,
  risk_rating        STRING,
  primary_contact    STRUCT<name STRING, email STRING, phone STRING>,
  categories         ARRAY<STRING>
);
