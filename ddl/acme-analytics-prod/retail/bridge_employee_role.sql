-- Source: retail.bridge_employee_role (15-bridge-and-scd2.hql)
-- Storage: Parquet → managed BQ table
-- Type mappings applied:
--   BIGINT employee_sk → INT64
--   BOOLEAN primary_role → BOOL
CREATE TABLE `acme-analytics-prod.retail.bridge_employee_role` (
  employee_sk  INT64,
  role         STRING,
  primary_role BOOL,
  eff_from     DATE,
  eff_to       DATE
);
