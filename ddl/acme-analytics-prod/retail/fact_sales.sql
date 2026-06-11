-- Source: retail.fact_sales (03-retail-tables.hql)
-- Storage: Parquet/Snappy → managed BQ table
-- Partition: PARTITIONED BY (sale_date DATE) → PARTITION BY sale_date
-- Cluster: CLUSTERED BY (customer_sk) INTO 8 BUCKETS → CLUSTER BY customer_sk
-- Type mappings applied:
--   BIGINT customer_sk, product_sk → INT64
--   INT quantity → INT64
--   DECIMAL(10,2) unit_price → NUMERIC(10,2)
--   DECIMAL(14,2) line_total → NUMERIC(14,2)
--   TIMESTAMP invoice_ts → DATETIME
CREATE TABLE `acme-analytics-prod.retail.fact_sales` (
  invoice_no  STRING,
  customer_sk INT64,
  product_sk  INT64,
  quantity    INT64,
  unit_price  NUMERIC(10,2),
  line_total  NUMERIC(14,2),
  country     STRING,
  invoice_ts  DATETIME,
  sale_date   DATE
)
PARTITION BY sale_date
CLUSTER BY customer_sk;
