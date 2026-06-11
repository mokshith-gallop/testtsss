-- Source: retail.acid_supplier_terms_history (13-additional-acid-tables.hql)
-- Storage: ORC/Snappy (ACID, transactional=true) → managed BQ table
-- ACID handling: transactional properties dropped; BQ supports DML natively
-- Cluster: CLUSTERED BY (supplier_sk) INTO 4 BUCKETS → CLUSTER BY supplier_sk
-- Type mappings applied:
--   BIGINT history_id, supplier_sk → INT64
--   INT payment_terms_days → INT64
--   DECIMAL(5,2) discount_pct → NUMERIC(5,2)
--   TIMESTAMP eff_from, eff_to → DATETIME
--   BOOLEAN is_current → BOOL
CREATE TABLE `acme-analytics-prod.retail.acid_supplier_terms_history` (
  history_id         INT64,
  supplier_sk        INT64,
  payment_terms_days INT64,
  discount_pct       NUMERIC(5,2),
  eff_from           DATETIME,
  eff_to             DATETIME,
  is_current         BOOL,
  changed_by         STRING
)
CLUSTER BY supplier_sk;
