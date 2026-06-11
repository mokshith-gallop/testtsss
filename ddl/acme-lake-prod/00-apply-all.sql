-- ============================================================================
-- acme-lake-prod: Master DDL Apply Script
-- ============================================================================
-- Converts the Hive raw + staging databases from the acme-lake cluster
-- to BigQuery DDL in the acme-lake-prod project.
--
-- Objects: 19 raw tables + 10 staging tables + 2 raw views + 1 staging view
--          = 32 total objects
--
-- Execution: Run each statement sequentially against BigQuery.
--   BigQuery does not support multi-statement scripts in all contexts,
--   so use bq CLI or a client library to execute each statement in order:
--
--   bq query --use_legacy_sql=false < 00-apply-all.sql
--
--   Or use the individual files under raw/ and staging/ directories.
--
-- Dependency order:
--   1. Dataset creation (raw, staging)
--   2. Raw tables (19) — alphabetical
--   3. Staging tables (10) — alphabetical
--   4. Views (3) — depend on tables existing
-- ============================================================================


-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 1: DATASET CREATION
-- ════════════════════════════════════════════════════════════════════════════

CREATE SCHEMA IF NOT EXISTS `acme-lake-prod.raw`
  OPTIONS (location = 'US');

CREATE SCHEMA IF NOT EXISTS `acme-lake-prod.staging`
  OPTIONS (location = 'US');


-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 2: RAW TABLES (19 tables)
-- ════════════════════════════════════════════════════════════════════════════

-- raw/chat_transcripts.sql
CREATE TABLE `acme-lake-prod.raw.chat_transcripts` (
  chat_id        STRING,
  customer_id    STRING,
  agent_id       STRING,
  started_at     DATETIME,
  ended_at       DATETIME,
  duration_sec   INT64,
  message_count  INT64,
  transcript     STRING,
  sentiment      NUMERIC(4,3),
  date_ts        STRING
)
PARTITION BY DATE(_PARTITIONTIME);

-- raw/customer_complaints.sql
CREATE TABLE `acme-lake-prod.raw.customer_complaints` (
  complaint_id  STRING,
  customer_id   STRING,
  invoice_no    STRING,
  channel       STRING,
  severity      STRING,
  summary       STRING,
  body          STRING,
  created_at    DATETIME,
  resolved_at   DATETIME,
  csat_score    INT64,
  date_ts       STRING
)
PARTITION BY DATE(_PARTITIONTIME);

-- raw/customer_signups.sql (Avro schema inlined from customer_signups-v3.avsc)
CREATE TABLE `acme-lake-prod.raw.customer_signups` (
  customer_id      STRING,
  email            STRING,
  phone            STRING,
  first_name       STRING,
  last_name        STRING,
  addr_line1       STRING,
  addr_city        STRING,
  addr_region      STRING,
  addr_country     STRING,
  addr_postal      STRING,
  signup_source    STRING,
  marketing_opt_in BOOL,
  signup_date      STRING
)
PARTITION BY DATE(_PARTITIONTIME);

-- raw/delivery_routes.sql
CREATE TABLE `acme-lake-prod.raw.delivery_routes` (
  route_id       STRING,
  driver_id      STRING,
  vehicle_id     STRING,
  planned_stops  INT64,
  actual_stops   INT64,
  miles_driven   NUMERIC(8,2),
  fuel_used      NUMERIC(8,2),
  start_ts       DATETIME,
  end_ts         DATETIME,
  date_ts        STRING
)
PARTITION BY DATE(_PARTITIONTIME);

-- raw/driver_logs.sql
CREATE TABLE `acme-lake-prod.raw.driver_logs` (
  driver_id    STRING,
  event_ts     DATETIME,
  event_type   STRING,
  gps          STRUCT<lat FLOAT64, lon FLOAT64>,
  notes        STRING,
  extras       JSON,
  date_ts      STRING
)
PARTITION BY DATE(_PARTITIONTIME);

-- raw/email_campaign_clicks.sql
CREATE TABLE `acme-lake-prod.raw.email_campaign_clicks` (
  campaign_id  STRING,
  send_id      STRING,
  recipient    STRING,
  clicked_at   DATETIME,
  click_url    STRING,
  user_agent   STRING,
  ip_address   STRING,
  geo          STRUCT<country STRING, region STRING, city STRING>,
  utm          JSON,
  date_ts      STRING
)
PARTITION BY DATE(_PARTITIONTIME);

-- raw/fraud_signals.sql (Avro schema inlined from fraud_signals-v5.avsc)
CREATE TABLE `acme-lake-prod.raw.fraud_signals` (
  customer_id    STRING,
  signal_type    STRING,
  score          FLOAT64,
  risk_band      STRING,
  reason_codes   ARRAY<STRING>,
  signal_ts      TIMESTAMP,
  vendor         STRING,
  signal_date    STRING
)
PARTITION BY DATE(_PARTITIONTIME);

-- raw/inventory_movements.sql
CREATE TABLE `acme-lake-prod.raw.inventory_movements` (
  movement_id    INT64,
  sku            STRING,
  warehouse_id   STRING,
  bin_location   STRING,
  movement_type  STRING,
  quantity       INT64,
  movement_ts    DATETIME,
  reference_doc  STRING,
  operator_id    STRING,
  reason_code    STRING,
  year           INT64,
  month          INT64,
  day            INT64
)
PARTITION BY DATE(_PARTITIONTIME);

-- raw/loyalty_events.sql (was RegexSerDe — SerDe dropped)
CREATE TABLE `acme-lake-prod.raw.loyalty_events` (
  event_ts_str   STRING,
  member_id      STRING,
  event_type     STRING,
  points         STRING,
  store_id       STRING,
  tx_id          STRING,
  meta_raw       STRING,
  date_ts        STRING
)
PARTITION BY DATE(_PARTITIONTIME);

-- raw/mobile_events.sql (TINYINT→INT64, MAP→JSON, STRUCT, ARRAY<STRUCT>)
CREATE TABLE `acme-lake-prod.raw.mobile_events` (
  event_id        STRING,
  event_ts        DATETIME,
  user_id         STRING,
  app_version     STRING,
  device_type     STRING,
  platform        STRING,
  properties      JSON,
  context         STRUCT<
                    ip         STRING,
                    country    STRING,
                    session_id STRING,
                    referrer   STRING
                  >,
  items           ARRAY<STRUCT<sku STRING, qty INT64, price NUMERIC(10,2)>>,
  event_date      STRING,
  hour_bucket     INT64
)
PARTITION BY DATE(_PARTITIONTIME);

-- raw/omniture_logs.sql (60 STRING columns)
CREATE TABLE `acme-lake-prod.raw.omniture_logs` (
  col_1  STRING, col_2  STRING, col_3  STRING, col_4  STRING, col_5  STRING,
  col_6  STRING, col_7  STRING, col_8  STRING, col_9  STRING, col_10 STRING,
  col_11 STRING, col_12 STRING, col_13 STRING, col_14 STRING, col_15 STRING,
  col_16 STRING, col_17 STRING, col_18 STRING, col_19 STRING, col_20 STRING,
  col_21 STRING, col_22 STRING, col_23 STRING, col_24 STRING, col_25 STRING,
  col_26 STRING, col_27 STRING, col_28 STRING, col_29 STRING, col_30 STRING,
  col_31 STRING, col_32 STRING, col_33 STRING, col_34 STRING, col_35 STRING,
  col_36 STRING, col_37 STRING, col_38 STRING, col_39 STRING, col_40 STRING,
  col_41 STRING, col_42 STRING, col_43 STRING, col_44 STRING, col_45 STRING,
  col_46 STRING, col_47 STRING, col_48 STRING, col_49 STRING, col_50 STRING,
  col_51 STRING, col_52 STRING, col_53 STRING, col_54 STRING, col_55 STRING,
  col_56 STRING, col_57 STRING, col_58 STRING, col_59 STRING, col_60 STRING,
  date_ts STRING
)
PARTITION BY DATE(_PARTITIONTIME);

-- raw/pos_transactions.sql
CREATE TABLE `acme-lake-prod.raw.pos_transactions` (
  txn_id          INT64,
  store_id        STRING,
  register_id     STRING,
  cashier_id      STRING,
  customer_id     STRING,
  invoice_no      STRING,
  txn_ts          DATETIME,
  line_count      INT64,
  gross_amount    NUMERIC(14,2),
  discount_amount NUMERIC(14,2),
  tax_amount      NUMERIC(14,2),
  tender_type     STRING,
  void_flag       BOOL,
  date_ts         STRING
)
PARTITION BY DATE(_PARTITIONTIME);

-- raw/product_catalog_feed.sql (was RCFILE — storage format dropped)
CREATE TABLE `acme-lake-prod.raw.product_catalog_feed` (
  sku             STRING,
  supplier_id     STRING,
  upc             STRING,
  name            STRING,
  category        STRING,
  subcategory     STRING,
  color           STRING,
  size            STRING,
  msrp            NUMERIC(10,2),
  cost            NUMERIC(10,2),
  available_from  DATE,
  discontinued_at DATE,
  metadata        JSON,
  feed_date       STRING
)
PARTITION BY DATE(_PARTITIONTIME);

-- raw/return_authorizations.sql
CREATE TABLE `acme-lake-prod.raw.return_authorizations` (
  rma_id         STRING,
  customer_id    STRING,
  invoice_no     STRING,
  stock_code     STRING,
  quantity       INT64,
  reason_code    STRING,
  reason_text    STRING,
  requested_at   DATETIME,
  approved       BOOL,
  refund_amount  NUMERIC(12,2),
  date_ts        STRING
)
PARTITION BY DATE(_PARTITIONTIME);

-- raw/returns_cdc.sql
CREATE TABLE `acme-lake-prod.raw.returns_cdc` (
  return_id      INT64,
  invoice_no     STRING,
  customer_sk    INT64,
  return_ts      DATETIME,
  refund_amount  NUMERIC(12,2),
  reason_code    STRING,
  status         STRING,
  op             STRING,
  snapshot_date  DATE
)
PARTITION BY snapshot_date;

-- raw/sales_retail.sql
CREATE TABLE `acme-lake-prod.raw.sales_retail` (
  invoice_no     STRING,
  stock_code     STRING,
  description    STRING,
  quantity       INT64,
  invoice_date   STRING,
  unit_price     NUMERIC(10,2),
  customer_id    STRING,
  country        STRING,
  date_ts        STRING
)
PARTITION BY DATE(_PARTITIONTIME);

-- raw/shipment_tracking.sql
CREATE TABLE `acme-lake-prod.raw.shipment_tracking` (
  tracking_no       STRING,
  carrier           STRING,
  invoice_no        STRING,
  customer_id       STRING,
  shipped_at        DATETIME,
  delivered_at      DATETIME,
  status            STRING,
  last_location     STRING,
  estimated_eta     DATETIME,
  date_ts           STRING,
  carrier_partition STRING
)
PARTITION BY DATE(_PARTITIONTIME)
CLUSTER BY carrier_partition;

-- raw/supplier_invoices.sql (was SEQUENCEFILE — storage format dropped)
CREATE TABLE `acme-lake-prod.raw.supplier_invoices` (
  invoice_no    STRING,
  supplier_id   STRING,
  invoice_date  DATE,
  due_date      DATE,
  total_amount  NUMERIC(14,2),
  currency      STRING,
  line_items    ARRAY<STRUCT<sku STRING, qty INT64, unit_price NUMERIC(10,2)>>,
  raw_xml       STRING,
  feed_year     INT64,
  feed_month    INT64
)
PARTITION BY DATE(_PARTITIONTIME);

-- raw/warehouse_picks.sql
CREATE TABLE `acme-lake-prod.raw.warehouse_picks` (
  pick_id                INT64,
  warehouse_id           STRING,
  bin_id                 STRING,
  sku                    STRING,
  picker_id              STRING,
  quantity               INT64,
  picked_at              DATETIME,
  duration_ms            INT64,
  date_ts                STRING,
  warehouse_id_partition STRING
)
PARTITION BY DATE(_PARTITIONTIME)
CLUSTER BY warehouse_id_partition;


-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 3: STAGING TABLES (10 tables)
-- ════════════════════════════════════════════════════════════════════════════

-- staging/cleansed_customers.sql
CREATE TABLE `acme-lake-prod.staging.cleansed_customers` (
  customer_id    STRING,
  email_norm     STRING,
  phone_norm     STRING,
  first_name     STRING,
  last_name      STRING,
  addr_line1     STRING,
  addr_city      STRING,
  addr_region    STRING,
  addr_country   STRING,
  addr_postal    STRING,
  geocoded_lat   FLOAT64,
  geocoded_lon   FLOAT64,
  eff_from_ts    DATETIME,
  record_hash    STRING,
  load_date      DATE
)
PARTITION BY load_date;

-- staging/cleansed_orders.sql
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
  order_date     DATE
)
PARTITION BY order_date;

-- staging/cleansed_products.sql
CREATE TABLE `acme-lake-prod.staging.cleansed_products` (
  sku            STRING,
  upc            STRING,
  name_norm      STRING,
  category_norm  STRING,
  subcategory    STRING,
  color_norm     STRING,
  size_norm      STRING,
  msrp           NUMERIC(10,2),
  cost           NUMERIC(10,2),
  supplier_id    STRING,
  available      BOOL,
  load_date      DATE
)
PARTITION BY load_date;

-- staging/dedup_clickstream.sql (CLUSTERED BY → CLUSTER BY, bucket count dropped)
CREATE TABLE `acme-lake-prod.staging.dedup_clickstream` (
  session_id     STRING,
  user_id        STRING,
  event_ts       DATETIME,
  page_url       STRING,
  referrer_url   STRING,
  ip             STRING,
  country        STRING,
  bot_score      NUMERIC(4,3),
  device_type    STRING,
  date_ts        STRING,
  country_partition STRING
)
PARTITION BY DATE(_PARTITIONTIME)
CLUSTER BY user_id, country_partition;

-- staging/fraud_scored.sql
CREATE TABLE `acme-lake-prod.staging.fraud_scored` (
  txn_id         INT64,
  customer_id    STRING,
  fraud_score    NUMERIC(5,4),
  risk_band      STRING,
  signals        ARRAY<STRING>,
  scored_at      DATETIME,
  score_date     DATE
)
PARTITION BY score_date;

-- staging/geocoded_addresses.sql
CREATE TABLE `acme-lake-prod.staging.geocoded_addresses` (
  raw_addr_hash  STRING,
  addr_line1     STRING,
  addr_city      STRING,
  addr_region    STRING,
  addr_country   STRING,
  addr_postal    STRING,
  lat            FLOAT64,
  lon            FLOAT64,
  confidence     NUMERIC(4,3),
  provider       STRING,
  load_date      DATE
)
PARTITION BY load_date;

-- staging/merged_returns_cdc.sql
CREATE TABLE `acme-lake-prod.staging.merged_returns_cdc` (
  return_id      INT64,
  invoice_no     STRING,
  customer_sk    INT64,
  return_ts      DATETIME,
  refund_amount  NUMERIC(12,2),
  reason_code    STRING,
  status         STRING,
  is_deleted     BOOL,
  snapshot_date  DATE
)
PARTITION BY snapshot_date;

-- staging/normalized_carrier_events.sql
CREATE TABLE `acme-lake-prod.staging.normalized_carrier_events` (
  tracking_no      STRING,
  carrier          STRING,
  event_type       STRING,
  event_ts         DATETIME,
  location_city    STRING,
  location_region  STRING,
  location_country STRING,
  date_ts          STRING
)
PARTITION BY DATE(_PARTITIONTIME);

-- staging/parsed_loyalty_events.sql
CREATE TABLE `acme-lake-prod.staging.parsed_loyalty_events` (
  event_ts       DATETIME,
  member_id      STRING,
  event_type     STRING,
  points         INT64,
  store_id       STRING,
  tx_id          STRING,
  meta           JSON,
  date_ts        STRING
)
PARTITION BY DATE(_PARTITIONTIME);

-- staging/warehouse_kpi_snapshot.sql
CREATE TABLE `acme-lake-prod.staging.warehouse_kpi_snapshot` (
  warehouse_id   STRING,
  snapshot_ts    DATETIME,
  units_in       INT64,
  units_picked   INT64,
  units_shipped  INT64,
  pick_rate_uph  NUMERIC(8,2),
  backlog_units  INT64,
  avg_pick_ms    INT64,
  date_ts        STRING
)
PARTITION BY DATE(_PARTITIONTIME);


-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 4: VIEWS (3 views — must run AFTER tables)
-- ════════════════════════════════════════════════════════════════════════════

-- raw/omniture.sql — projection view over omniture_logs
CREATE OR REPLACE VIEW `acme-lake-prod.raw.omniture` AS
SELECT
    col_2  AS event_ts,
    col_8  AS ip,
    col_13 AS url,
    col_14 AS user_id,
    col_50 AS city,
    col_51 AS country,
    col_53 AS state,
    date_ts
FROM `acme-lake-prod.raw.omniture_logs`;

-- raw/v_fraud_signals_recent.sql — last 24h fraud signals
CREATE OR REPLACE VIEW `acme-lake-prod.raw.v_fraud_signals_recent` AS
SELECT *
FROM `acme-lake-prod.raw.fraud_signals`
WHERE signal_date >= FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY));

-- staging/v_returns_pending.sql — returns awaiting approval
CREATE OR REPLACE VIEW `acme-lake-prod.staging.v_returns_pending` AS
SELECT
    r.rma_id,
    r.customer_id,
    r.invoice_no,
    r.stock_code,
    r.quantity,
    r.requested_at,
    DATE_DIFF(CURRENT_DATE(), DATE(r.requested_at), DAY) AS days_pending
FROM `acme-lake-prod.raw.return_authorizations` r
WHERE r.approved IS NULL OR r.approved = FALSE;
