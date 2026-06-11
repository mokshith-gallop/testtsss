-- Source: retail.dim_store (10-additional-dims.hql)
-- Storage: Parquet/Snappy → managed BQ table
-- Type mappings applied:
--   BIGINT store_sk, manager_employee_sk → INT64
--   INT sq_ft → INT64
--   MAP<STRING,STRING> attributes → JSON
CREATE TABLE `acme-analytics-prod.retail.dim_store` (
  store_sk            INT64,
  store_id            STRING,
  store_name          STRING,
  store_type          STRING,
  region              STRING,
  city                STRING,
  state               STRING,
  country             STRING,
  open_dt             DATE,
  close_dt            DATE,
  sq_ft               INT64,
  manager_employee_sk INT64,
  attributes          JSON
);
