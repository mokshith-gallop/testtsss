-- Source: retail.dim_employee (10-additional-dims.hql)
-- Storage: Parquet/Snappy → managed BQ table
-- Type mappings applied:
--   BIGINT cols → INT64
CREATE TABLE `acme-analytics-prod.retail.dim_employee` (
  employee_sk    INT64,
  employee_id    STRING,
  first_name     STRING,
  last_name      STRING,
  hire_dt        DATE,
  termination_dt DATE,
  role           STRING,
  department     STRING,
  home_store_sk  INT64,
  manager_sk     INT64,
  salary_band    STRING
);
