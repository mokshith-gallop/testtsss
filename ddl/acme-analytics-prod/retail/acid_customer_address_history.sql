-- Source: retail.acid_customer_address_history (13-additional-acid-tables.hql)
-- Storage: ORC/Snappy (ACID, transactional=true) → managed BQ table
-- ACID handling: transactional properties dropped; BQ supports DML natively
-- Cluster: CLUSTERED BY (customer_sk) INTO 8 BUCKETS → CLUSTER BY customer_sk
-- Type mappings applied:
--   BIGINT history_id, customer_sk → INT64
--   TIMESTAMP eff_from, eff_to → DATETIME
--   BOOLEAN is_current → BOOL
CREATE TABLE `acme-analytics-prod.retail.acid_customer_address_history` (
  history_id      INT64,
  customer_sk     INT64,
  address_line1   STRING,
  address_city    STRING,
  address_region  STRING,
  address_country STRING,
  address_postal  STRING,
  eff_from        DATETIME,
  eff_to          DATETIME,
  is_current      BOOL,
  change_reason   STRING
)
CLUSTER BY customer_sk;
