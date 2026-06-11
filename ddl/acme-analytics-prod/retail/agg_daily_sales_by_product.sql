-- Source: retail.agg_daily_sales_by_product (12-aggregates-rollups.hql)
-- Storage: Parquet → managed BQ table
-- Partition: PARTITIONED BY (sale_date DATE) → PARTITION BY sale_date
-- Type mappings applied:
--   BIGINT product_sk, units_sold, return_units, net_units → INT64
--   DECIMAL(16,2) gross_revenue, cogs → NUMERIC(16,2)
--   DECIMAL(6,4) margin_pct → NUMERIC(6,4)
CREATE TABLE `acme-analytics-prod.retail.agg_daily_sales_by_product` (
  product_sk    INT64,
  units_sold    INT64,
  gross_revenue NUMERIC(16,2),
  margin_pct    NUMERIC(6,4),
  cogs          NUMERIC(16,2),
  return_units  INT64,
  net_units     INT64,
  sale_date     DATE
)
PARTITION BY sale_date;
