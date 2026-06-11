-- Source: retail.dim_store_history (15-bridge-and-scd2.hql)
-- Storage: Parquet → managed BQ table
-- Type mappings applied:
--   BIGINT history_id, store_sk, manager_employee_sk → INT64
--   INT sq_ft → INT64
--   BOOLEAN is_current → BOOL
CREATE TABLE `acme-analytics-prod.retail.dim_store_history` (
  history_id          INT64,
  store_sk            INT64,
  store_type          STRING,
  manager_employee_sk INT64,
  sq_ft               INT64,
  eff_from            DATE,
  eff_to              DATE,
  is_current          BOOL,
  change_reason       STRING
);
