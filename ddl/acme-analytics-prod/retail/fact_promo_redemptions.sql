-- Source: retail.fact_promo_redemptions (11-additional-facts.hql)
-- Storage: Parquet → managed BQ table
-- Partition: PARTITIONED BY (redemption_date DATE) → PARTITION BY redemption_date
-- Type mappings applied:
--   BIGINT redemption_id, promo_sk, customer_sk → INT64
--   DECIMAL(12,2) discount_amount → NUMERIC(12,2)
--   TIMESTAMP applied_ts → DATETIME
CREATE TABLE `acme-analytics-prod.retail.fact_promo_redemptions` (
  redemption_id   INT64,
  promo_sk        INT64,
  invoice_no      STRING,
  customer_sk     INT64,
  discount_amount NUMERIC(12,2),
  applied_ts      DATETIME,
  channel         STRING,
  redemption_date DATE
)
PARTITION BY redemption_date;
