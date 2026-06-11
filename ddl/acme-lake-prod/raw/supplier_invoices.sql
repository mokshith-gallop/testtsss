-- Source: raw.supplier_invoices (05-additional-raw-feeds.hql)
-- Storage: SEQUENCEFILE → managed BQ table (STORED AS SEQUENCEFILE dropped)
-- Type mappings:
--   ARRAY<STRUCT<sku:STRING, qty:INT, unit_price:DECIMAL(10,2)>>
--     → ARRAY<STRUCT<sku STRING, qty INT64, unit_price NUMERIC(10,2)>>
-- Partition: feed_year INT, feed_month INT → ingestion-time partitioning
--   Feed_year and feed_month preserved as INT64 columns.
CREATE TABLE `acme-lake-prod.raw.supplier_invoices` (
  invoice_no    STRING,
  supplier_id   STRING,
  invoice_date  DATE,
  due_date      DATE,
  total_amount  NUMERIC(14,2),
  currency      STRING,
  line_items    ARRAY<STRUCT<sku STRING, qty INT64, unit_price NUMERIC(10,2)>>,
  raw_xml       STRING,
  -- Hive partition columns inlined
  feed_year     INT64,
  feed_month    INT64
)
PARTITION BY DATE(_PARTITIONTIME);
