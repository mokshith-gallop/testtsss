-- Source: retail.acid_loyalty_points_ledger (13-additional-acid-tables.hql)
-- Storage: ORC/Snappy (ACID, transactional=true) → managed BQ table
-- ACID handling: transactional properties dropped; BQ supports DML natively
-- Cluster: CLUSTERED BY (member_id) INTO 8 BUCKETS → CLUSTER BY member_id
-- Type mappings applied:
--   BIGINT entry_id → INT64
--   INT points_delta, running_balance → INT64
--   TIMESTAMP event_ts, expiry_ts → DATETIME
CREATE TABLE `acme-analytics-prod.retail.acid_loyalty_points_ledger` (
  entry_id        INT64,
  member_id       STRING,
  points_delta    INT64,
  running_balance INT64,
  event_ts        DATETIME,
  event_type      STRING,
  reference_id    STRING,
  expiry_ts       DATETIME
)
CLUSTER BY member_id;
