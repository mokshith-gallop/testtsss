-- Source: retail.bridge_product_supplier (15-bridge-and-scd2.hql)
-- Storage: Parquet → managed BQ table
-- Type mappings applied:
--   BIGINT product_sk, supplier_sk → INT64
--   BOOLEAN primary_supplier → BOOL
--   DECIMAL(12,4) unit_cost → NUMERIC(12,4)
--   INT lead_time_days, moq → INT64
CREATE TABLE `acme-analytics-prod.retail.bridge_product_supplier` (
  product_sk       INT64,
  supplier_sk      INT64,
  primary_supplier BOOL,
  supplier_sku     STRING,
  unit_cost        NUMERIC(12,4),
  lead_time_days   INT64,
  moq              INT64,
  valid_from       DATE,
  valid_to         DATE
);
