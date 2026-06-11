-- Source: retail.kudu_realtime_price (14-kudu-realtime.hql)
-- Storage: Kudu → managed BQ table
-- Kudu handling: PRIMARY KEY, PARTITION BY HASH, STORED AS KUDU, TBLPROPERTIES dropped
-- Cluster: PRIMARY KEY (sku, store_id) → CLUSTER BY sku, store_id
-- Type mappings applied:
--   DECIMAL(10,2) price, list_price, cost → NUMERIC(10,2)
--   DECIMAL(5,4) margin_pct → NUMERIC(5,4)
--   BIGINT updated_ts → INT64
CREATE TABLE `acme-analytics-prod.retail.kudu_realtime_price` (
  sku            STRING,
  store_id       STRING,
  price          NUMERIC(10,2),
  list_price     NUMERIC(10,2),
  cost           NUMERIC(10,2),
  margin_pct     NUMERIC(5,4),
  updated_ts     INT64,
  pricing_engine STRING
)
CLUSTER BY sku, store_id;
