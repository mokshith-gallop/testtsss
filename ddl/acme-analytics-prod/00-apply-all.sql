-- ============================================================================
-- acme-analytics-prod: Master DDL Apply Script
-- ============================================================================
-- Converts the Hive retail database from the acme-analytics cluster
-- to BigQuery DDL in the acme-analytics-prod project.
--
-- Objects: 58 tables + 11 views = 69 total objects
--   - 15 dimension tables (dim_*)
--   - 17 fact tables (fact_*)
--   - 10 aggregate/special tables (agg_*, sales_cube, top_countries_daily)
--   - 5 ACID tables (returns_ledger, acid_*)
--   - 5 bridge tables (bridge_*)
--   - 2 SCD-2 history tables (dim_employee_history, dim_store_history)
--   - 4 Kudu tables (inventory_realtime, kudu_*)
--   - 11 views (vw_*)
--
-- Execution: Run each statement sequentially against BigQuery.
--   BigQuery does not support multi-statement scripts in all contexts,
--   so use bq CLI or a client library to execute each statement in order:
--
--   bq query --use_legacy_sql=false < 00-apply-all.sql
--
--   Or use the individual files under retail/ directory.
--
-- Dependency order:
--   1. Dataset creation (retail)
--   2. Dimension tables (15) — no dependencies
--   3. Fact tables (17) — reference dims via FK conventions
--   4. Aggregate/special tables (10)
--   5. ACID tables (5)
--   6. Bridge tables (5) + SCD-2 history tables (2)
--   7. Kudu tables (4)
--   8. UDFs (normalize_country_js — prerequisite for vw_panel_continuity_score)
--   9. Views (11) — depend on tables + UDFs existing
-- ============================================================================


-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 1: DATASET CREATION
-- ════════════════════════════════════════════════════════════════════════════

CREATE SCHEMA IF NOT EXISTS `acme-analytics-prod.retail`
  OPTIONS (location = 'US');


-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 2: DIMENSION TABLES (15 tables)
-- ════════════════════════════════════════════════════════════════════════════

-- retail/dim_date.sql
CREATE TABLE `acme-analytics-prod.retail.dim_date` (
  d_date_sk           INT64,
  d_date_id           STRING,
  d_date              DATE,
  d_month_seq         INT64,
  d_week_seq          INT64,
  d_quarter_seq       INT64,
  d_year              INT64,
  d_dow               INT64,
  d_moy               INT64,
  d_dom               INT64,
  d_qoy               INT64,
  d_fy_year           INT64,
  d_fy_quarter_seq    INT64,
  d_day_name          STRING,
  d_holiday           STRING,
  d_weekend           STRING,
  d_following_holiday STRING,
  d_first_dom         INT64,
  d_last_dom          INT64,
  d_same_day_ly       INT64,
  d_same_day_lq       INT64,
  d_current_day       STRING,
  d_current_week      STRING,
  d_current_month     STRING,
  d_current_quarter   STRING,
  d_current_year      STRING
);

-- retail/dim_customer.sql
CREATE TABLE `acme-analytics-prod.retail.dim_customer` (
  customer_sk   INT64,
  customer_id   STRING,
  country       STRING,
  first_seen_ts DATETIME,
  last_seen_ts  DATETIME
);

-- retail/dim_product.sql
CREATE TABLE `acme-analytics-prod.retail.dim_product` (
  product_sk  INT64,
  stock_code  STRING,
  description STRING,
  unit_price  NUMERIC(10,2)
);

-- retail/dim_store.sql
CREATE TABLE `acme-analytics-prod.retail.dim_store` (
  store_sk            INT64,
  store_id            STRING,
  store_name          STRING,
  store_type          STRING,
  region              STRING,
  city                STRING,
  state               STRING,
  country             STRING,
  open_dt             DATE,
  close_dt            DATE,
  sq_ft               INT64,
  manager_employee_sk INT64,
  attributes          JSON
);

-- retail/dim_supplier.sql
CREATE TABLE `acme-analytics-prod.retail.dim_supplier` (
  supplier_sk        INT64,
  supplier_id        STRING,
  supplier_name      STRING,
  country            STRING,
  tax_id             STRING,
  payment_terms_days INT64,
  onboard_dt         DATE,
  risk_rating        STRING,
  primary_contact    STRUCT<name STRING, email STRING, phone STRING>,
  categories         ARRAY<STRING>
);

-- retail/dim_employee.sql
CREATE TABLE `acme-analytics-prod.retail.dim_employee` (
  employee_sk    INT64,
  employee_id    STRING,
  first_name     STRING,
  last_name      STRING,
  hire_dt        DATE,
  termination_dt DATE,
  role           STRING,
  department     STRING,
  home_store_sk  INT64,
  manager_sk     INT64,
  salary_band    STRING
);

-- retail/dim_promotion.sql
CREATE TABLE `acme-analytics-prod.retail.dim_promotion` (
  promo_sk    INT64,
  promo_id    STRING,
  name        STRING,
  promo_type  STRING,
  pct_off     NUMERIC(5,2),
  flat_off    NUMERIC(10,2),
  start_dt    DATE,
  end_dt      DATE,
  budget      NUMERIC(14,2),
  channels    ARRAY<STRING>,
  eligibility JSON
);

-- retail/dim_warehouse.sql
CREATE TABLE `acme-analytics-prod.retail.dim_warehouse` (
  warehouse_sk   INT64,
  warehouse_id   STRING,
  name           STRING,
  type           STRING,
  operator       STRING,
  region         STRING,
  capacity_units INT64,
  open_dt        DATE,
  geocode        STRUCT<lat FLOAT64, lon FLOAT64>
);

-- retail/dim_currency.sql
CREATE TABLE `acme-analytics-prod.retail.dim_currency` (
  currency_code STRING,
  currency_name STRING,
  minor_unit    INT64,
  symbol        STRING
);

-- retail/dim_geography.sql
CREATE TABLE `acme-analytics-prod.retail.dim_geography` (
  geo_sk       INT64,
  country_iso2 STRING,
  country_name STRING,
  region_code  STRING,
  region_name  STRING,
  city         STRING,
  postal_code  STRING,
  timezone     STRING,
  latitude     FLOAT64,
  longitude    FLOAT64
);

-- retail/dim_color.sql
CREATE TABLE `acme-analytics-prod.retail.dim_color` (
  color_sk     INT64,
  color_code   STRING,
  color_name   STRING,
  color_family STRING,
  hex_code     STRING
);

-- retail/dim_size.sql
CREATE TABLE `acme-analytics-prod.retail.dim_size` (
  size_sk     INT64,
  size_code   STRING,
  size_name   STRING,
  size_system STRING,
  sort_order  INT64
);

-- retail/dim_brand.sql
CREATE TABLE `acme-analytics-prod.retail.dim_brand` (
  brand_sk       INT64,
  brand_id       STRING,
  brand_name     STRING,
  parent_company STRING,
  private_label  BOOL,
  launch_dt      DATE
);

-- retail/dim_category.sql
CREATE TABLE `acme-analytics-prod.retail.dim_category` (
  category_sk INT64,
  category_id STRING,
  parent_id   STRING,
  name        STRING,
  depth       INT64,
  sort_order  INT64
);

-- retail/dim_payment_method.sql
CREATE TABLE `acme-analytics-prod.retail.dim_payment_method` (
  payment_method_sk INT64,
  method_code       STRING,
  method_name       STRING,
  category          STRING,
  fee_pct           NUMERIC(5,4),
  fee_flat          NUMERIC(8,2),
  settlement_days   INT64
);


-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 3: FACT TABLES (17 tables)
-- ════════════════════════════════════════════════════════════════════════════

-- retail/fact_sales.sql
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

-- retail/fact_web_session.sql
CREATE TABLE `acme-analytics-prod.retail.fact_web_session` (
  event_ts   DATETIME,
  ip         STRING,
  url        STRING,
  user_id    STRING,
  city       STRING,
  state      STRING,
  event_date DATE,
  country    STRING
)
PARTITION BY event_date;

-- retail/fact_inventory_movements.sql
CREATE TABLE `acme-analytics-prod.retail.fact_inventory_movements` (
  movement_id    INT64,
  movement_ts    DATETIME,
  sku            STRING,
  warehouse_sk   INT64,
  store_sk       INT64,
  movement_type  STRING,
  quantity       INT64,
  reference_doc  STRING,
  reason_code    STRING,
  operator_sk    INT64,
  year           INT64,
  month          INT64,
  day            INT64,
  region         STRING,
  _partition_date DATE
)
PARTITION BY _partition_date
CLUSTER BY sku;

-- retail/fact_inventory_snapshot.sql
CREATE TABLE `acme-analytics-prod.retail.fact_inventory_snapshot` (
  sku              STRING,
  warehouse_sk     INT64,
  on_hand_units    INT64,
  allocated_units  INT64,
  in_transit_units INT64,
  available_units  INT64,
  avg_cost         NUMERIC(12,4),
  last_movement_ts DATETIME,
  snapshot_date    DATE
)
PARTITION BY snapshot_date
CLUSTER BY sku;

-- retail/fact_returns.sql
CREATE TABLE `acme-analytics-prod.retail.fact_returns` (
  return_id      INT64,
  invoice_no     STRING,
  customer_sk    INT64,
  product_sk     INT64,
  return_ts      DATETIME,
  quantity       INT64,
  refund_amount  NUMERIC(12,2),
  reason_code    STRING,
  return_channel STRING,
  store_sk       INT64,
  return_date    DATE
)
PARTITION BY return_date;

-- retail/fact_payments.sql
CREATE TABLE `acme-analytics-prod.retail.fact_payments` (
  payment_id              INT64,
  invoice_no              STRING,
  customer_sk             INT64,
  payment_method_sk       INT64,
  amount                  NUMERIC(14,2),
  currency_code           STRING,
  payment_ts              DATETIME,
  auth_code               STRING,
  settlement_id           STRING,
  fee_amount              NUMERIC(10,2),
  post_year               INT64,
  post_month              INT64,
  payment_method_partition STRING,
  _partition_month        DATE
)
PARTITION BY DATE_TRUNC(_partition_month, MONTH)
CLUSTER BY invoice_no;

-- retail/fact_shipments.sql
CREATE TABLE `acme-analytics-prod.retail.fact_shipments` (
  shipment_id      STRING,
  invoice_no       STRING,
  customer_sk      INT64,
  warehouse_sk     INT64,
  carrier          STRING,
  tracking_no      STRING,
  shipped_ts       DATETIME,
  delivered_ts     DATETIME,
  sla_hours        INT64,
  tracking_events  ARRAY<STRUCT<ts DATETIME, status STRING, location STRING>>,
  ship_year        INT64,
  ship_month       INT64,
  ship_day         INT64,
  carrier_partition STRING,
  _partition_date  DATE
)
PARTITION BY _partition_date
CLUSTER BY warehouse_sk;

-- retail/fact_refunds.sql
CREATE TABLE `acme-analytics-prod.retail.fact_refunds` (
  refund_id     INT64,
  payment_id    INT64,
  return_id     INT64,
  customer_sk   INT64,
  amount        NUMERIC(14,2),
  currency_code STRING,
  refund_ts     DATETIME,
  refund_method STRING,
  refund_date   DATE
)
PARTITION BY refund_date;

-- retail/fact_app_clicks.sql
CREATE TABLE `acme-analytics-prod.retail.fact_app_clicks` (
  session_id          STRING,
  user_sk             INT64,
  event_ts            DATETIME,
  event_type          STRING,
  screen              STRING,
  target_id           STRING,
  properties          JSON,
  device              STRUCT<platform STRING, version STRING, model STRING>,
  event_date          DATE,
  platform_partition  STRING
)
PARTITION BY event_date;

-- retail/fact_email_engagement.sql
CREATE TABLE `acme-analytics-prod.retail.fact_email_engagement` (
  send_id     STRING,
  campaign_sk INT64,
  user_sk     INT64,
  event_type  STRING,
  event_ts    DATETIME,
  link_url    STRING,
  clicks      ARRAY<STRUCT<ts DATETIME, url STRING>>,
  event_date  DATE
)
PARTITION BY event_date;

-- retail/fact_chat_interactions.sql
CREATE TABLE `acme-analytics-prod.retail.fact_chat_interactions` (
  chat_id       STRING,
  customer_sk   INT64,
  agent_sk      INT64,
  started_at    DATETIME,
  ended_at      DATETIME,
  duration_sec  INT64,
  message_count INT64,
  resolved      BOOL,
  csat_score    INT64,
  sentiment_avg NUMERIC(4,3),
  start_date    DATE
)
PARTITION BY start_date;

-- retail/fact_warehouse_picks.sql
CREATE TABLE `acme-analytics-prod.retail.fact_warehouse_picks` (
  pick_id             INT64,
  warehouse_sk        INT64,
  picker_sk           INT64,
  sku                 STRING,
  quantity            INT64,
  picked_ts           DATETIME,
  duration_ms         INT64,
  bin_location        STRING,
  pick_date           DATE,
  warehouse_partition STRING
)
PARTITION BY pick_date
CLUSTER BY picker_sk;

-- retail/fact_supplier_invoice_lines.sql
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
  invoice_year    INT64,
  invoice_month   INT64,
  _partition_month DATE
)
PARTITION BY DATE_TRUNC(_partition_month, MONTH);

-- retail/fact_loyalty_events.sql
CREATE TABLE `acme-analytics-prod.retail.fact_loyalty_events` (
  event_id   INT64,
  member_id  STRING,
  event_type STRING,
  points     INT64,
  store_sk   INT64,
  tx_id      STRING,
  event_ts   DATETIME,
  meta       JSON,
  event_date DATE
)
PARTITION BY event_date;

-- retail/fact_fraud_decisions.sql
CREATE TABLE `acme-analytics-prod.retail.fact_fraud_decisions` (
  txn_id        INT64,
  customer_sk   INT64,
  fraud_score   NUMERIC(5,4),
  decision      STRING,
  rule_signals  ARRAY<STRING>,
  decided_ts    DATETIME,
  decision_date DATE
)
PARTITION BY decision_date;

-- retail/fact_promo_redemptions.sql
CREATE TABLE `acme-analytics-prod.retail.fact_promo_redemptions` (
  redemption_id   INT64,
  promo_sk        INT64,
  invoice_no      STRING,
  customer_sk     INT64,
  discount_amount NUMERIC(12,2),
  applied_ts      DATETIME,
  channel         STRING,
  redemption_date DATE
)
PARTITION BY redemption_date;

-- retail/fact_customer_complaints.sql
CREATE TABLE `acme-analytics-prod.retail.fact_customer_complaints` (
  complaint_id STRING,
  customer_sk  INT64,
  invoice_no   STRING,
  channel      STRING,
  severity     STRING,
  summary      STRING,
  created_at   DATETIME,
  resolved_at  DATETIME,
  csat_score   INT64,
  created_date DATE
)
PARTITION BY created_date;


-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 4: AGGREGATE / SPECIAL TABLES (10 tables)
-- ════════════════════════════════════════════════════════════════════════════

-- retail/sales_cube.sql
CREATE TABLE `acme-analytics-prod.retail.sales_cube` (
  dim_level  INT64,
  cube_key   STRING,
  country    STRING,
  month_key  INT64,
  product_sk INT64,
  orders     INT64,
  revenue    NUMERIC(18,2),
  units      INT64,
  as_of_date DATE
)
PARTITION BY as_of_date;

-- retail/top_countries_daily.sql
CREATE TABLE `acme-analytics-prod.retail.top_countries_daily` (
  as_of_date DATE,
  country    STRING,
  orders     INT64,
  revenue    NUMERIC(18,2),
  rank       INT64
);

-- retail/agg_daily_sales_by_store.sql
CREATE TABLE `acme-analytics-prod.retail.agg_daily_sales_by_store` (
  store_sk      INT64,
  gross_revenue NUMERIC(16,2),
  net_revenue   NUMERIC(16,2),
  units_sold    INT64,
  txn_count     INT64,
  avg_basket    NUMERIC(12,2),
  sale_date     DATE
)
PARTITION BY sale_date;

-- retail/agg_daily_sales_by_product.sql
CREATE TABLE `acme-analytics-prod.retail.agg_daily_sales_by_product` (
  product_sk    INT64,
  units_sold    INT64,
  gross_revenue NUMERIC(16,2),
  margin_pct    NUMERIC(6,4),
  cogs          NUMERIC(16,2),
  return_units  INT64,
  net_units     INT64,
  sale_date     DATE
)
PARTITION BY sale_date;

-- retail/agg_weekly_customer_ltv.sql
CREATE TABLE `acme-analytics-prod.retail.agg_weekly_customer_ltv` (
  customer_sk         INT64,
  ltv_to_date         NUMERIC(16,2),
  orders_to_date      INT64,
  avg_order_value     NUMERIC(12,2),
  days_since_last_order INT64,
  rfm_score           STRING,
  churn_risk          NUMERIC(4,3),
  week_start_date     DATE
)
PARTITION BY week_start_date;

-- retail/agg_monthly_supplier_performance.sql
CREATE TABLE `acme-analytics-prod.retail.agg_monthly_supplier_performance` (
  supplier_sk        INT64,
  orders_placed      INT64,
  units_received     INT64,
  on_time_pct        NUMERIC(5,4),
  fill_rate_pct      NUMERIC(5,4),
  avg_lead_time_days NUMERIC(6,2),
  quality_score      NUMERIC(4,3),
  total_spend        NUMERIC(16,2),
  month_start        DATE
)
PARTITION BY month_start;

-- retail/agg_hourly_warehouse_kpi.sql
CREATE TABLE `acme-analytics-prod.retail.agg_hourly_warehouse_kpi` (
  warehouse_sk     INT64,
  units_in         INT64,
  units_picked     INT64,
  units_shipped    INT64,
  pick_rate_uph    NUMERIC(8,2),
  backlog_units    INT64,
  avg_pick_seconds NUMERIC(8,2),
  snapshot_hour    STRING,
  _partition_date  DATE
)
PARTITION BY _partition_date;

-- retail/agg_daily_carrier_otd.sql
CREATE TABLE `acme-analytics-prod.retail.agg_daily_carrier_otd` (
  carrier           STRING,
  shipments_total   INT64,
  delivered_on_time INT64,
  delivered_late    INT64,
  in_transit        INT64,
  otd_pct           NUMERIC(5,4),
  avg_transit_hours NUMERIC(8,2),
  ship_date         DATE
)
PARTITION BY ship_date;

-- retail/agg_marketing_attribution_cube.sql
CREATE TABLE `acme-analytics-prod.retail.agg_marketing_attribution_cube` (
  channel            STRING,
  campaign_sk        INT64,
  region             STRING,
  attributed_revenue NUMERIC(16,2),
  attributed_units   INT64,
  cost               NUMERIC(14,2),
  roas               NUMERIC(8,4),
  grouping_id        INT64,
  period_date        DATE
)
PARTITION BY period_date;

-- retail/agg_returns_by_reason_monthly.sql
CREATE TABLE `acme-analytics-prod.retail.agg_returns_by_reason_monthly` (
  reason_code        STRING,
  return_count       INT64,
  return_units       INT64,
  total_refunded     NUMERIC(16,2),
  avg_days_to_return NUMERIC(8,2),
  month_start        DATE
)
PARTITION BY month_start;


-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 5: ACID TABLES (5 tables)
-- ACID handling: transactional properties dropped; BQ supports DML natively.
-- CLUSTER BY preserves the original Hive bucketing column.
-- ════════════════════════════════════════════════════════════════════════════

-- retail/returns_ledger.sql
CREATE TABLE `acme-analytics-prod.retail.returns_ledger` (
  return_id     INT64,
  invoice_no    STRING,
  customer_sk   INT64,
  return_ts     DATETIME,
  refund_amount NUMERIC(12,2),
  reason_code   STRING,
  status        STRING
)
CLUSTER BY return_id;

-- retail/acid_customer_address_history.sql
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

-- retail/acid_supplier_terms_history.sql
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

-- retail/acid_loyalty_points_ledger.sql
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

-- retail/acid_inventory_adjustments_log.sql
CREATE TABLE `acme-analytics-prod.retail.acid_inventory_adjustments_log` (
  adjustment_id INT64,
  warehouse_sk  INT64,
  sku           STRING,
  quantity_delta INT64,
  reason_code   STRING,
  notes         STRING,
  adjusted_by   STRING,
  adjusted_at   DATETIME,
  approved_by   STRING,
  approved_at   DATETIME
)
CLUSTER BY adjustment_id;


-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 6: BRIDGE TABLES (5) + SCD-2 HISTORY TABLES (2)
-- ════════════════════════════════════════════════════════════════════════════

-- retail/bridge_product_attribute.sql
CREATE TABLE `acme-analytics-prod.retail.bridge_product_attribute` (
  product_sk      INT64,
  attribute_name  STRING,
  attribute_value STRING,
  primary_value   BOOL,
  sort_order      INT64
);

-- retail/bridge_product_supplier.sql
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

-- retail/bridge_customer_segment.sql
CREATE TABLE `acme-analytics-prod.retail.bridge_customer_segment` (
  customer_sk  INT64,
  segment_id   STRING,
  segment_name STRING,
  assigned_dt  DATE,
  expires_dt   DATE,
  confidence   NUMERIC(4,3),
  source       STRING,
  snapshot_date DATE
)
PARTITION BY snapshot_date;

-- retail/bridge_promo_eligibility.sql
CREATE TABLE `acme-analytics-prod.retail.bridge_promo_eligibility` (
  customer_sk INT64,
  promo_sk    INT64,
  eligible    BOOL,
  reason      STRING,
  valid_from  DATE,
  valid_to    DATE,
  load_date   DATE
)
PARTITION BY load_date;

-- retail/bridge_employee_role.sql
CREATE TABLE `acme-analytics-prod.retail.bridge_employee_role` (
  employee_sk  INT64,
  role         STRING,
  primary_role BOOL,
  eff_from     DATE,
  eff_to       DATE
);

-- retail/dim_employee_history.sql (SCD-2)
CREATE TABLE `acme-analytics-prod.retail.dim_employee_history` (
  history_id    INT64,
  employee_sk   INT64,
  role          STRING,
  department    STRING,
  home_store_sk INT64,
  salary_band   STRING,
  eff_from      DATE,
  eff_to        DATE,
  is_current    BOOL,
  eff_from_year INT64,
  _partition_year DATE
)
PARTITION BY DATE_TRUNC(_partition_year, YEAR);

-- retail/dim_store_history.sql (SCD-2)
CREATE TABLE `acme-analytics-prod.retail.dim_store_history` (
  history_id          INT64,
  store_sk            INT64,
  store_type          STRING,
  manager_employee_sk INT64,
  sq_ft               INT64,
  eff_from            DATE,
  eff_to              DATE,
  is_current          BOOL,
  change_reason       STRING
);


-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 7: KUDU TABLES (4 tables)
-- Kudu handling: PRIMARY KEY → CLUSTER BY, PARTITION BY HASH → dropped,
-- STORED AS KUDU → dropped, TBLPROPERTIES → dropped.
-- ════════════════════════════════════════════════════════════════════════════

-- retail/inventory_realtime.sql (renamed from kudu_inventory_realtime)
CREATE TABLE `acme-analytics-prod.retail.inventory_realtime` (
  warehouse_id    STRING,
  sku             STRING,
  on_hand         INT64,
  allocated       INT64,
  available       INT64,
  last_updated_ts INT64
)
CLUSTER BY warehouse_id, sku;

-- retail/kudu_session_state.sql
CREATE TABLE `acme-analytics-prod.retail.kudu_session_state` (
  session_id     STRING,
  user_id        STRING,
  started_ts     INT64,
  last_event_ts  INT64,
  cart_value     NUMERIC(12,2),
  cart_items     INT64,
  current_screen STRING,
  platform       STRING,
  geo_country    STRING
)
CLUSTER BY session_id;

-- retail/kudu_promo_eligibility.sql
CREATE TABLE `acme-analytics-prod.retail.kudu_promo_eligibility` (
  customer_id        STRING,
  promo_id           STRING,
  eligible           BOOL,
  eligibility_reason STRING,
  valid_from_ts      INT64,
  valid_to_ts        INT64,
  redeemed           BOOL
)
CLUSTER BY customer_id, promo_id;

-- retail/kudu_realtime_price.sql
CREATE TABLE `acme-analytics-prod.retail.kudu_realtime_price` (
  sku            STRING,
  store_id       STRING,
  price          NUMERIC(10,2),
  list_price     NUMERIC(10,2),
  cost           NUMERIC(10,2),
  margin_pct     NUMERIC(5,4),
  updated_ts     INT64,
  pricing_engine STRING
)
CLUSTER BY sku, store_id;


-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 8: UDFs (must run BEFORE views that reference them)
-- ════════════════════════════════════════════════════════════════════════════

-- Placeholder JS UDF for normalize_country (ported from com.acme.udf.NormalizeCountry)
-- Required by: vw_panel_continuity_score (UDF in JOIN ON clause)
-- TODO: Replace with actual implementation from Java UDF port
CREATE OR REPLACE FUNCTION `acme-analytics-prod.retail.normalize_country_js`(country STRING)
RETURNS STRING
LANGUAGE js AS r"""
  if (country == null) return null;
  var s = country.trim().toUpperCase();
  // Common normalisations — expand as needed from the Java source
  var map = {
    'UK': 'GB', 'UNITED KINGDOM': 'GB', 'GREAT BRITAIN': 'GB', 'ENGLAND': 'GB',
    'US': 'US', 'USA': 'US', 'UNITED STATES': 'US', 'UNITED STATES OF AMERICA': 'US',
    'DE': 'DE', 'GERMANY': 'DE', 'DEUTSCHLAND': 'DE',
    'FR': 'FR', 'FRANCE': 'FR',
    'JP': 'JP', 'JAPAN': 'JP',
    'AU': 'AU', 'AUSTRALIA': 'AU',
    'CA': 'CA', 'CANADA': 'CA',
  };
  return map[s] || s;
""";


-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 9: VIEWS (11 views — must run AFTER tables + UDFs)
-- ════════════════════════════════════════════════════════════════════════════

-- retail/vw_daily_sales_by_country.sql (green path)
CREATE OR REPLACE VIEW `acme-analytics-prod.retail.vw_daily_sales_by_country` AS
WITH daily AS (
  SELECT
    sale_date,
    country,
    COUNT(DISTINCT invoice_no)                  AS orders,
    SUM(line_total)                             AS revenue,
    SUM(quantity)                               AS units,
    COUNT(DISTINCT customer_sk)                 AS active_customers
  FROM `acme-analytics-prod.retail.fact_sales`
  GROUP BY sale_date, country
)
SELECT
  d.sale_date,
  d.country,
  d.orders,
  d.revenue,
  d.units,
  d.active_customers,
  COALESCE(d.revenue / NULLIF(d.orders, 0), 0)  AS aov,
  COALESCE(d.units  / NULLIF(d.orders, 0), 0)   AS basket_size
FROM daily d;

-- retail/vw_weekly_sales_with_running_totals.sql (green path)
CREATE OR REPLACE VIEW `acme-analytics-prod.retail.vw_weekly_sales_with_running_totals` AS
WITH weekly AS (
  SELECT
    d.d_week_seq,
    d.d_year,
    SUM(f.line_total) AS wk_revenue,
    SUM(f.quantity)   AS wk_units
  FROM `acme-analytics-prod.retail.fact_sales` f
  JOIN `acme-analytics-prod.retail.dim_date` d ON d.d_date = f.sale_date
  GROUP BY d.d_week_seq, d.d_year
)
SELECT
  w.d_week_seq,
  w.d_year,
  w.wk_revenue,
  w.wk_units,
  SUM(w.wk_revenue) OVER (
    PARTITION BY w.d_year
    ORDER BY w.d_week_seq
  )                                                              AS ytd_revenue,
  AVG(w.wk_revenue) OVER (
    ORDER BY w.d_week_seq
    ROWS BETWEEN 12 PRECEDING AND CURRENT ROW
  )                                                              AS rolling_13wk_avg,
  LAG(w.wk_revenue, 52) OVER (ORDER BY w.d_week_seq)            AS same_week_last_year,
  w.wk_revenue - COALESCE(LAG(w.wk_revenue, 52) OVER (ORDER BY w.d_week_seq), 0)
                                                                 AS yoy_delta
FROM weekly w;

-- retail/vw_customer_lifetime_value.sql (R8: DATEDIFF → DATE_DIFF)
CREATE OR REPLACE VIEW `acme-analytics-prod.retail.vw_customer_lifetime_value` AS
WITH per_customer AS (
  SELECT
    c.customer_sk,
    c.customer_id,
    c.country,
    MIN(f.sale_date)              AS first_order_date,
    MAX(f.sale_date)              AS last_order_date,
    COUNT(DISTINCT f.invoice_no)  AS orders,
    SUM(f.line_total)             AS lifetime_revenue
  FROM `acme-analytics-prod.retail.dim_customer` c
  LEFT JOIN `acme-analytics-prod.retail.fact_sales` f ON f.customer_sk = c.customer_sk
  GROUP BY c.customer_sk, c.customer_id, c.country
)
SELECT
  customer_sk,
  customer_id,
  country,
  first_order_date,
  last_order_date,
  orders,
  lifetime_revenue,
  DATE_DIFF(CURRENT_DATE(), last_order_date, DAY)  AS recency_days,
  CASE
    WHEN orders = 0                                              THEN 'never'
    WHEN DATE_DIFF(CURRENT_DATE(), last_order_date, DAY) <= 30   THEN 'active'
    WHEN DATE_DIFF(CURRENT_DATE(), last_order_date, DAY) <= 90   THEN 'warm'
    WHEN DATE_DIFF(CURRENT_DATE(), last_order_date, DAY) <= 365  THEN 'cold'
    ELSE 'churned'
  END                                                AS rfm_bucket
FROM per_customer;

-- retail/vw_product_performance.sql (green path)
CREATE OR REPLACE VIEW `acme-analytics-prod.retail.vw_product_performance` AS
WITH sold AS (
  SELECT
    p.product_sk,
    p.stock_code,
    p.description,
    f.country,
    SUM(f.line_total)                AS revenue,
    SUM(f.quantity)                  AS units,
    COUNT(DISTINCT f.invoice_no)     AS orders
  FROM `acme-analytics-prod.retail.dim_product` p
  JOIN `acme-analytics-prod.retail.fact_sales` f ON f.product_sk = p.product_sk
  GROUP BY p.product_sk, p.stock_code, p.description, f.country
),
ranked AS (
  SELECT
    s.*,
    RANK()       OVER (PARTITION BY s.country ORDER BY s.revenue DESC)  AS country_rank,
    DENSE_RANK() OVER (                       ORDER BY s.revenue DESC)  AS global_rank
  FROM sold s
)
SELECT * FROM ranked;

-- retail/vw_monthly_cohort_retention.sql (R8: DATE_FORMAT, MONTHS_BETWEEN, to_date)
CREATE OR REPLACE VIEW `acme-analytics-prod.retail.vw_monthly_cohort_retention` AS
WITH first_order AS (
  SELECT
    customer_sk,
    FORMAT_DATE('%Y-%m', MIN(sale_date)) AS cohort_month
  FROM `acme-analytics-prod.retail.fact_sales`
  GROUP BY customer_sk
),
orders AS (
  SELECT
    f.customer_sk,
    fo.cohort_month,
    FORMAT_DATE('%Y-%m', f.sale_date)                                                  AS order_month,
    DATE_DIFF(f.sale_date, PARSE_DATE('%Y-%m-%d', CONCAT(fo.cohort_month, '-01')), MONTH) AS months_since_first
  FROM `acme-analytics-prod.retail.fact_sales` f
  JOIN first_order fo ON fo.customer_sk = f.customer_sk
)
SELECT
  cohort_month,
  CAST(months_since_first AS INT64)    AS months_since_first,
  COUNT(DISTINCT customer_sk)          AS active_customers
FROM orders
GROUP BY cohort_month, CAST(months_since_first AS INT64);

-- retail/vw_session_to_order_attribution.sql (cross-project, R9: INTERVAL syntax)
CREATE OR REPLACE VIEW `acme-analytics-prod.retail.vw_session_to_order_attribution` AS
SELECT
  s.user_id,
  s.event_ts                                AS session_ts,
  s.context.referrer                        AS referrer,
  f.invoice_no,
  f.invoice_ts                              AS order_ts,
  f.line_total
FROM `acme-lake-prod.raw.mobile_events` s
LEFT JOIN `acme-analytics-prod.retail.dim_customer` dc ON dc.customer_id = s.user_id
LEFT JOIN `acme-analytics-prod.retail.fact_sales` f
       ON  f.customer_sk = dc.customer_sk
       AND f.invoice_ts BETWEEN s.event_ts AND DATETIME_ADD(s.event_ts, INTERVAL 1 DAY);

-- retail/vw_active_member_panel.sql (R3: NDV → APPROX_COUNT_DISTINCT, date_sub syntax)
CREATE OR REPLACE VIEW `acme-analytics-prod.retail.vw_active_member_panel` AS
SELECT
    region,
    APPROX_COUNT_DISTINCT(member_id)   AS approx_active_members,
    COUNT(DISTINCT member_id)          AS exact_active_members,
    SUM(points)                        AS total_points_redeemed
FROM `acme-analytics-prod.retail.fact_loyalty_events`
WHERE event_type = 'REDEEM'
  AND event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY region;

-- retail/vw_sales_rollup_by_region.sql (R4: WITH ROLLUP, GROUPING__ID)
CREATE OR REPLACE VIEW `acme-analytics-prod.retail.vw_sales_rollup_by_region` AS
SELECT
    s.region,
    s.store_sk,
    SUM(f.line_total)                                        AS total_revenue,
    COUNT(*)                                                 AS line_count,
    GROUPING(s.region) * 2 + GROUPING(s.store_sk)           AS grouping_level
FROM `acme-analytics-prod.retail.fact_sales` f
JOIN `acme-analytics-prod.retail.dim_store` s ON s.store_sk = f.customer_sk
WHERE f.sale_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY ROLLUP(s.region, s.store_sk);

-- retail/vw_category_hierarchy_recursive.sql (R10: WITH RECURSIVE pass-through)
CREATE OR REPLACE VIEW `acme-analytics-prod.retail.vw_category_hierarchy_recursive` AS
WITH RECURSIVE cat_tree (category_id, name, parent_id, path, depth) AS (
    SELECT category_id, name, parent_id, name AS path, 0 AS depth
    FROM `acme-analytics-prod.retail.dim_category`
    WHERE parent_id IS NULL OR parent_id = ''

    UNION ALL

    SELECT c.category_id, c.name, c.parent_id,
           CONCAT(t.path, ' > ', c.name)  AS path,
           t.depth + 1                    AS depth
    FROM `acme-analytics-prod.retail.dim_category` c
    JOIN cat_tree t ON c.parent_id = t.category_id
    WHERE t.depth < 8
)
SELECT * FROM cat_tree;

-- retail/vw_panel_continuity_score.sql (T4: normalize_country → normalize_country_js)
CREATE OR REPLACE VIEW `acme-analytics-prod.retail.vw_panel_continuity_score` AS
SELECT
    f.customer_sk,
    COUNT(DISTINCT f.sale_date)         AS active_days,
    COUNT(DISTINCT f.product_sk)        AS distinct_products,
    SUM(f.line_total)                   AS total_spend
FROM `acme-analytics-prod.retail.fact_sales` f
JOIN `acme-analytics-prod.retail.dim_customer` c
  ON c.customer_sk = f.customer_sk
 AND normalize_country_js(c.country) = normalize_country_js(f.country)
WHERE f.sale_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
GROUP BY f.customer_sk;

-- retail/vw_otd_by_carrier_30d.sql (R9: INTERVAL, unix_timestamp → UNIX_SECONDS)
CREATE OR REPLACE VIEW `acme-analytics-prod.retail.vw_otd_by_carrier_30d` AS
SELECT
    carrier,
    COUNT(*)                                                                              AS shipments,
    AVG(CASE WHEN delivered_ts <= DATETIME_ADD(shipped_ts, INTERVAL 48 HOUR)
             THEN 1.0 ELSE 0.0 END)                                                      AS otd_rate,
    AVG(UNIX_SECONDS(CAST(delivered_ts AS TIMESTAMP)) - UNIX_SECONDS(CAST(shipped_ts AS TIMESTAMP))) / 3600.0 AS avg_transit_hours
FROM `acme-analytics-prod.retail.fact_shipments`
WHERE CAST(shipped_ts AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY carrier;
