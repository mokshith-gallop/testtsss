-- Source: retail.dim_employee_history (15-bridge-and-scd2.hql)
-- Storage: Parquet → managed BQ table
-- Partition: PARTITIONED BY (eff_from_year INT)
--   → Synthetic _partition_year DATE; eff_from_year inlined as regular INT64 column
--   ETL must populate: _partition_year = DATE(eff_from_year, 1, 1)
-- Type mappings applied:
--   BIGINT history_id, employee_sk, home_store_sk → INT64
--   BOOLEAN is_current → BOOL
--   INT eff_from_year → INT64 (inlined partition col)
CREATE TABLE `acme-analytics-prod.retail.dim_employee_history` (
  history_id    INT64,
  employee_sk   INT64,
  role          STRING,
  department    STRING,
  home_store_sk INT64,
  salary_band   STRING,
  eff_from      DATE,
  eff_to        DATE,
  is_current    BOOL,
  -- Hive partition column inlined
  eff_from_year INT64,
  -- Synthetic partition column
  _partition_year DATE
)
PARTITION BY DATE_TRUNC(_partition_year, YEAR);
