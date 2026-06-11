-- Source: retail.fact_supplier_invoice_lines (11-additional-facts.hql)
-- Storage: Parquet → managed BQ table
-- Partition: PARTITIONED BY (invoice_year INT, invoice_month INT)
--   → Synthetic _partition_month DATE; original partition cols inlined as regular columns
--   ETL must populate: _partition_month = DATE(invoice_year, invoice_month, 1)
-- Type mappings applied:
--   BIGINT invoice_line_id, supplier_sk → INT64
--   INT quantity → INT64
--   DECIMAL(12,4) unit_cost → NUMERIC(12,4)
--   DECIMAL(14,2) line_total → NUMERIC(14,2)
--   TIMESTAMP received_ts → DATETIME
--   INT invoice_year, invoice_month → INT64 (inlined partition cols)
CREATE TABLE `acme-analytics-prod.retail.fact_supplier_invoice_lines` (
  invoice_line_id INT64,
  invoice_no      STRING,
  supplier_sk     INT64,
  sku             STRING,
  quantity        INT64,
  unit_cost       NUMERIC(12,4),
  line_total      NUMERIC(14,2),
  currency_code   STRING,
  received_ts     DATETIME,
  -- Inlined partition columns (were PARTITIONED BY in Hive)
  invoice_year    INT64,
  invoice_month   INT64,
  -- Synthetic partition column
  _partition_month DATE
)
PARTITION BY DATE_TRUNC(_partition_month, MONTH);
