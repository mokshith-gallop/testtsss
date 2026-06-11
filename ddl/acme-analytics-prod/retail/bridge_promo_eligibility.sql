-- Source: retail.bridge_promo_eligibility (15-bridge-and-scd2.hql)
-- Storage: Parquet → managed BQ table
-- Partition: PARTITIONED BY (load_date DATE) → PARTITION BY load_date
-- Type mappings applied:
--   BIGINT customer_sk, promo_sk → INT64
--   BOOLEAN eligible → BOOL
CREATE TABLE `acme-analytics-prod.retail.bridge_promo_eligibility` (
  customer_sk INT64,
  promo_sk    INT64,
  eligible    BOOL,
  reason      STRING,
  valid_from  DATE,
  valid_to    DATE,
  load_date   DATE
)
PARTITION BY load_date;
