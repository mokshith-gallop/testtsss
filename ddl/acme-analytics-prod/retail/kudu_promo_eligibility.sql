-- Source: retail.kudu_promo_eligibility (14-kudu-realtime.hql)
-- Storage: Kudu → managed BQ table
-- Kudu handling: PRIMARY KEY, PARTITION BY HASH, STORED AS KUDU, TBLPROPERTIES dropped
-- Cluster: PRIMARY KEY (customer_id, promo_id) → CLUSTER BY customer_id, promo_id
-- Type mappings applied:
--   BOOLEAN eligible, redeemed → BOOL
--   BIGINT valid_from_ts, valid_to_ts → INT64
CREATE TABLE `acme-analytics-prod.retail.kudu_promo_eligibility` (
  customer_id        STRING,
  promo_id           STRING,
  eligible           BOOL,
  eligibility_reason STRING,
  valid_from_ts      INT64,
  valid_to_ts        INT64,
  redeemed           BOOL
)
CLUSTER BY customer_id, promo_id;
