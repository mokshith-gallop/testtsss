-- Source: staging.cleansed_orders (06-staging-tables.hql)
-- Storage: PARQUET → managed BQ table
-- Dropped: STORED AS PARQUET, TBLPROPERTIES ('parquet.compression'='SNAPPY')
-- Partition: order_date DATE → direct DATE partitioning
CREATE TABLE `acme-lake-prod.staging.cleansed_orders` (
  order_id       STRING,
  customer_id    STRING,
  invoice_no     STRING,
  txn_ts         DATETIME,
  line_count     INT64,
  gross_amount   NUMERIC(14,2),
  discount       NUMERIC(14,2),
  tax            NUMERIC(14,2),
  net_amount     NUMERIC(14,2),
  tender_type    STRING,
  source_feed    STRING,
  -- Hive partition column inlined (DATE type maps directly)
  order_date     DATE
)
PARTITION BY order_date;
