-- Source: retail.agg_daily_sales_by_store (12-aggregates-rollups.hql)
-- Storage: Parquet → managed BQ table
-- Partition: PARTITIONED BY (sale_date DATE) → PARTITION BY sale_date
-- Type mappings applied:
--   BIGINT store_sk, units_sold, txn_count → INT64
--   DECIMAL(16,2) gross_revenue, net_revenue → NUMERIC(16,2)
--   DECIMAL(12,2) avg_basket → NUMERIC(12,2)
CREATE TABLE `acme-analytics-prod.retail.agg_daily_sales_by_store` (
  store_sk      INT64,
  gross_revenue NUMERIC(16,2),
  net_revenue   NUMERIC(16,2),
  units_sold    INT64,
  txn_count     INT64,
  avg_basket    NUMERIC(12,2),
  sale_date     DATE
)
PARTITION BY sale_date;
