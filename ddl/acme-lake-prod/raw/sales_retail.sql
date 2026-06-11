-- Source: raw.sales_retail (02-raw-external-tables.hql)
-- Storage: TEXTFILE (CSV) → managed BQ table
-- Partition: date_ts STRING → ingestion-time partitioning
--   date_ts is preserved as STRING for data fidelity; load scripts should
--   set the partition decorator based on date_ts value.
CREATE TABLE `acme-lake-prod.raw.sales_retail` (
  invoice_no     STRING,
  stock_code     STRING,
  description    STRING,
  quantity       INT64,
  invoice_date   STRING,
  unit_price     NUMERIC(10,2),
  customer_id    STRING,
  country        STRING,
  -- Hive partition column inlined
  date_ts        STRING
)
PARTITION BY DATE(_PARTITIONTIME);
