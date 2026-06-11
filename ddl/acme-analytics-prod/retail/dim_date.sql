-- Source: retail.dim_date (03-retail-tables.hql)
-- Storage: Parquet/Snappy → managed BQ table
-- Type mappings applied:
--   BIGINT d_date_sk → INT64
--   INT cols → INT64
CREATE TABLE `acme-analytics-prod.retail.dim_date` (
  d_date_sk           INT64,
  d_date_id           STRING,
  d_date              DATE,
  d_month_seq         INT64,
  d_week_seq          INT64,
  d_quarter_seq       INT64,
  d_year              INT64,
  d_dow               INT64,
  d_moy               INT64,
  d_dom               INT64,
  d_qoy               INT64,
  d_fy_year           INT64,
  d_fy_quarter_seq    INT64,
  d_day_name          STRING,
  d_holiday           STRING,
  d_weekend           STRING,
  d_following_holiday STRING,
  d_first_dom         INT64,
  d_last_dom          INT64,
  d_same_day_ly       INT64,
  d_same_day_lq       INT64,
  d_current_day       STRING,
  d_current_week      STRING,
  d_current_month     STRING,
  d_current_quarter   STRING,
  d_current_year      STRING
);
